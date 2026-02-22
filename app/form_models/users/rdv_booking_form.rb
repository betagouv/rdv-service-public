class Users::RdvBookingForm
  include Users::UserFormConcern

  attr_reader :rdv_builder, :invitation_token
  attr_accessor :booking_for_proche

  delegate :to_query, :motif, :service, to: :rdv_builder
  delegate :add_benign_error, :ignore_benign_errors, :relatives_attributes=, to: :user
  validates :ants_pre_demande_number, presence: true, if: -> { rdv.requires_ants_predemande_number? }
  validates_with AntsPreDemandeNumberStatusValidation, if: -> { rdv.requires_ants_predemande_number? }

  validate :validate_ants_pre_demandes_count
  validate :validate_phone_number_present_for_motif_by_phone
  validate :validate_proches

  def initialize(user:, rdv_builder:, domain:, user_attributes: {}, booking_for_proche: false, selected_proche: nil, ants_selected_relative_ids: [])
    @user = user
    @rdv_builder = rdv_builder
    @domain = domain
    @booking_for_proche = booking_for_proche
    @selected_proche = selected_proche
    @ants_selected_relative_ids = ants_selected_relative_ids.map(&:to_s)
    @user.singleton_class.accepts_nested_attributes_for :relatives
    enrich_relatives_attributes!(user_attributes)
    @user.assign_attributes(user_attributes)
  end

  def save
    # on ne permet la mise à jour de l'email que s'il était vide
    @user.skip_reconfirmation! if @user.email_was.blank?

    return false unless valid?

    ActiveRecord::Base.transaction do
      @user.save!
      rdv_builder.rdv.collectif? ? create_collectif_participation : create_individual_rdv
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def users_for_rdv
    if ants_with_proches?
      [@user] + (@user.relatives.target || []).compact
    elsif booking_for_proche? && @selected_proche == "new"
      [(@user.relatives.target || []).find(&:persisted?)]
    elsif booking_for_proche? && @selected_proche.present?
      [@user.relatives.find(@selected_proche)]
    else
      [@user]
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def new_proche
    return unless booking_for_proche? && !ants_with_proches?

    @new_proche ||= @user.relatives.target&.find(&:new_record?) ||
                    @user.relatives.build(
                      created_through: "user_relative_creation",
                      organisation_ids: @user.organisation_ids
                    )
  end

  def submitted_ants_selected_ids = @ants_selected_relative_ids

  def new_ants_proches
    return [] unless ants_with_proches?

    count = rdv_builder.ants_pre_demandes_count.to_i - 1
    built = (@user.relatives.target || []).select(&:new_record?)
    extras_count = [count - built.size, 0].max
    built + extras_count.times.map { User.new }
  end

  def show_birth_date_field? = !signed_in_with_invitation_token? && rdv.territory&.enable_birth_date_field?

  def show_ants_pre_demande_number_field? = rdv.requires_ants_predemande_number?

  def show_logement_field? = rdv.territory.enable_logement_field

  def show_address_field? = !signed_in_with_invitation_token? && rdv.territory.enable_address_field?

  def address_required? = motif.home?

  def phone_required? = motif.phone?

  def address_value = user.address.nil? ? to_query[:where] : user.address

  def show_social_fields? = service.nil? || service.user_field_groups.include?(:social)

  def ants_meeting_point_id = rdv_builder.lieu_id

  def rdv = @rdv || rdv_builder.rdv

  def booking_for_proche? = @booking_for_proche

  private

  def ants_with_proches?
    rdv.requires_ants_predemande_number? && rdv_builder.ants_pre_demandes_count.to_i > 1
  end

  def should_process_proches? = booking_for_proche? || ants_with_proches?

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def enrich_relatives_attributes!(attrs)
    return unless attrs[:relatives_attributes]

    attrs[:relatives_attributes] = attrs[:relatives_attributes].values.filter_map do |rel_attrs|
      rel_attrs = rel_attrs.symbolize_keys
      if rel_attrs[:id].present?
        # Proche existant : inclure seulement si coché (cas ANTS)
        next if ants_with_proches? && @ants_selected_relative_ids.exclude?(rel_attrs[:id].to_s)

        rel_attrs
      else
        # Rejeter si un proche existant est sélectionné (cas non-ANTS)
        next if !ants_with_proches? && @selected_proche.present? && @selected_proche != "new"

        rel_attrs.merge(created_through: "user_relative_creation", organisation_ids: @user.organisation_ids)
      end
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def validate_proches
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
    count = rdv_builder.ants_pre_demandes_count
    return if count.blank?

    errors.add(:base, "Veuillez choisir un nombre de pré-demandes entre 1 et 6") unless AntsPreDemandesCountValidator.count_valid?(count)
  end

  def validate_phone_number_present_for_motif_by_phone
    errors.add(:phone_number, :missing_for_phone_motif) if rdv.motif.phone? && user.phone_number.blank?
  end

  def create_individual_rdv
    @rdv = rdv_builder.creneau.build_rdv
    @rdv.assign_attributes(users: users_for_rdv, created_by: @user)

    @rdv.save!

    notifier = Notifiers::RdvCreated.new(@rdv, @user)
    notifier.perform
    @invitation_token = notifier.participations_tokens_by_user_id[@user.id]
  end

  def create_collectif_participation
    participation = Participation.new(rdv:, user: users_for_rdv.first, created_by: @user)
    # authorize(participation, policy_class: User::ParticipationPolicy)

    participation.create_and_notify!(@user)
    @invitation_token = participation.restricted_auth_token
  end
end
