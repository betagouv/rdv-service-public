class Users::RdvBookingForm
  include Users::UserFormConcern

  attr_accessor :booking_for_proche
  attr_reader :rdv_builder, :invitation_token, :rdv, :ants_selected_relative_ids

  delegate :to_query, :motif, :service, :ants_pre_demandes_count, to: :rdv_builder
  delegate :add_benign_error, :ignore_benign_errors, :relatives_attributes=, to: :user
  delegate :collectif?, :requires_ants_predemande_number?, to: :rdv

  validates :ants_pre_demande_number, presence: true, if: :requires_ants_predemande_number?
  validates_with AntsPreDemandeNumberStatusValidation, if: :requires_ants_predemande_number?
  validate :validate_ants_pre_demandes_count, if: :requires_ants_predemande_number?
  validate :validate_ants_proches_numbers, if: :ants_with_proches?

  validate :validate_phone_number_present_for_motif_by_phone

  def initialize(user:, rdv_builder:, domain:, user_attributes: {}, booking_for_proche: false, selected_proche: nil, ants_selected_relative_ids: [])
    @user = user
    @rdv_builder = rdv_builder
    @rdv = rdv_builder.rdv
    @domain = domain
    @booking_for_proche = booking_for_proche
    @selected_proche = selected_proche
    @ants_selected_relative_ids = ants_selected_relative_ids.map(&:to_s)
    @user.singleton_class.accepts_nested_attributes_for :relatives
    enrich_relatives_attributes!(user_attributes)
    @user.assign_attributes(user_attributes)
  end

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      @user.save!
      @newly_created_proche = (@user.relatives.target || []).find(&:persisted?) if booking_for_new_proche?
      rdv.collectif? ? create_participation : create_individual_rdv
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def show_birth_date_field? = !signed_in_with_invitation_token? && rdv.territory&.enable_birth_date_field?

  def show_ants_pre_demande_number_field? = requires_ants_predemande_number?

  def show_logement_field? = rdv.territory.enable_logement_field

  def show_address_field? = !signed_in_with_invitation_token? && rdv.territory.enable_address_field?

  def address_required? = motif.home?

  def phone_required? = motif.phone?

  def address_value = user.address.nil? ? to_query[:where] : user.address

  def show_social_fields? = service.nil? || service.user_field_groups.include?(:social)

  def booking_for_proche? = @booking_for_proche
  def booking_for_new_proche? = booking_for_proche? && @selected_proche == "new"
  def booking_for_existing_proche? = booking_for_proche? && @selected_proche.present?

  def ants_meeting_point_id = rdv_builder.lieu_id

  def new_participation
    # user_id: plutôt que user: pour éviter que inverse_of ajoute @new_participation à @user.participations
    # ce qui déclencherait un autosave prématuré lors de @user.save! et ferait échouer create_and_notify!
    # Fallback to @user.id when the proche isn't persisted yet (e.g. during the authorization check before save)
    @new_participation ||= Participation.new(rdv:, user_id: users_for_rdv.first&.id || @user.id, created_by: @user)
  end

  def new_proche
    @new_proche ||=
      @user.relatives.target&.find(&:new_record?) || # nécessaire pour afficher les erreurs de validation sur les nouveaux proches
      @user.relatives.build
  end

  def new_ants_proches
    return [] unless ants_with_proches?

    count = ants_pre_demandes_count.to_i - 1
    built = (@user.relatives.target || []).select(&:new_record?)
    extras_count = [count - built.size, 0].max
    built + extras_count.times.map { User.new }
  end

  private

  def ants_with_proches?
    rdv.requires_ants_predemande_number? && ants_pre_demandes_count.to_i > 1
  end

  def enrich_relatives_attributes!(attrs)
    return unless attrs[:relatives_attributes]

    attrs[:relatives_attributes] = attrs[:relatives_attributes].values.map(&:symbolize_keys).filter_map do |rel_attrs|
      if rel_attrs[:id].present?
        # dans le cas ANTS on peut vouloir mettre à jour les proches avec le numéro de pré-demande
        rel_attrs if ants_with_proches? && @ants_selected_relative_ids.include?(rel_attrs[:id].to_s)
      elsif ants_with_proches? || @selected_proche == "new"
        # pour les nouveaux proches on s'assure de les créer avec le bon flag
        rel_attrs.merge(created_through: "user_relative_creation")
      end
    end
  end

  def validate_ants_proches_numbers
    return unless ants_with_proches?

    (@user.relatives.target || []).each_with_index do |relative, index|
      prefix = "Proche #{index + 1}"
      number = relative.ants_pre_demande_number
      if number.blank?
        errors.add(:base, "#{prefix} : le numéro de pré-demande ANTS doit être renseigné")
      elsif !number.upcase.match?(AntsPreDemandeNumberFormatValidator::REGEX)
        errors.add(:base, "#{prefix} : le numéro de pré-demande ANTS doit comporter 10 chiffres et lettres")
      end
    end
  end

  def validate_ants_pre_demandes_count
    unless AntsPreDemandesCountValidator.count_valid?(ants_pre_demandes_count)
      errors.add(:base, "Veuillez choisir un nombre de pré-demandes entre 1 et 6")
    end
  end

  def validate_phone_number_present_for_motif_by_phone
    errors.add(:phone_number, :missing_for_phone_motif) if rdv.motif.phone? && user.phone_number.blank?
  end

  def create_individual_rdv
    @rdv = rdv_builder.creneau.build_rdv # TODO: ce comportement est extrêmement surprenant, à refacto avec le RdvBuilder
    @rdv.assign_attributes(users: users_for_rdv, created_by: @user)
    @rdv.save!
    notifier = Notifiers::RdvCreated.new(@rdv, @user)
    notifier.perform
    @invitation_token = notifier.participations_tokens_by_user_id[@user.id]
  end

  def create_participation
    # new_participation may have been built before @user.save! (e.g. during the authorization check),
    # so users_for_rdv.first was nil and user_id fell back to @user.id. Re-evaluate now that the
    # proche has been persisted and has a real id.
    new_participation.user_id = users_for_rdv.first&.id
    new_participation.create_and_notify!(@user)
    @invitation_token = new_participation.restricted_auth_token
  end

  def users_for_rdv
    if ants_with_proches?
      [@user] + (@user.relatives.target || []).compact
    elsif booking_for_new_proche?
      [@newly_created_proche]
    elsif booking_for_existing_proche?
      [@user.relatives.find(@selected_proche)]
    else
      [@user]
    end
  end
end
