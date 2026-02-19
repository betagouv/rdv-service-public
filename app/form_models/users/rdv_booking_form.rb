class Users::RdvBookingForm
  include Users::UserFormConcern

  attr_reader :rdv_builder, :invitation_token
  attr_accessor :booking_for_proche

  delegate :to_query, :motif, :service, to: :rdv_builder
  delegate :add_benign_error, :ignore_benign_errors, to: :user
  validates :ants_pre_demande_number, presence: true, if: -> { rdv.requires_ants_predemande_number? }
  validates_with AntsPreDemandeNumberStatusValidation, if: -> { rdv.requires_ants_predemande_number? }

  validate :validate_ants_pre_demandes_count
  validate :validate_phone_number_present_for_motif_by_phone
  validate :validate_proches

  def initialize(user:, rdv_builder:, domain:, user_attributes: {})
    @user = user
    @rdv_builder = rdv_builder
    @domain = domain
    @booking_for_proche = user_attributes.delete(:booking_for_proche)
    @raw_proches_data = user_attributes.delete(:proches) || {}
    @selected_proche = user_attributes.delete(:selected_proche)
    @user_attributes = user_attributes
    @user.assign_attributes(user_attributes)
  end

  def save
    # on ne permet la mise à jour de l'email que s'il était vide
    @user.skip_reconfirmation! if @user.email_was.blank?

    return false unless valid?

    ActiveRecord::Base.transaction do
      @user.save!
      save_proches!
      create_rdv
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def users_for_rdv
    if ants_with_proches?
      [@user] + saved_proches
    elsif booking_for_proche? && saved_proches.any?
      saved_proches
    else
      [@user]
    end
  end

  def submitted_proches_data = @raw_proches_data

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

  # Retourne les données du/des proche(s) à traiter
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def selected_proches_data
    return [] unless should_process_proches?

    if ants_with_proches?
      # Cas ANTS : chaque slot a un selected_id et des données par proche
      @raw_proches_data.values.map(&:symbolize_keys).filter_map do |proche_data|
        selected_id = proche_data[:selected_id]&.to_s
        proches_in_slot = proche_data[:proches].stringify_keys
        data = (proches_in_slot[selected_id] || {}).symbolize_keys
        data[:id] = selected_id unless selected_id == "new"
        data
      end
    else
      # Cas normal : un seul proche sélectionné via radio
      return [] if @selected_proche.blank?

      data = (@raw_proches_data[@selected_proche] || @raw_proches_data[@selected_proche.to_s] || {}).symbolize_keys
      data[:id] = @selected_proche unless @selected_proche == "new"
      [data]
    end
  end

  def validate_proches
    return unless should_process_proches?

    selected_proches_data.each_with_index do |attrs, index|
      prefix = "Proche #{index + 1}"
      errors.add(:base, "#{prefix} : le prénom doit être renseigné") if attrs[:first_name].blank?
      errors.add(:base, "#{prefix} : le nom doit être renseigné") if attrs[:last_name].blank?

      next unless ants_with_proches?

      number = attrs[:ants_pre_demande_number]
      if number.blank?
        errors.add(:base, "#{prefix} : le numéro de pré-demande ANTS doit être renseigné")
      elsif !number.upcase.match?(AntsPreDemandeNumberFormatValidator::REGEX)
        errors.add(:base, "#{prefix} : le numéro de pré-demande ANTS doit comporter 10 chiffres et lettres")
      end
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def save_proches!
    return unless should_process_proches?

    @saved_proches = selected_proches_data.map do |attrs|
      proche = find_or_build_proche(attrs)
      proche.assign_attributes(attrs.slice(:first_name, :last_name, :birth_date, :ants_pre_demande_number))
      proche.save!
      proche.reload
    end
  end

  def find_or_build_proche(attrs)
    if attrs[:id].present? && attrs[:id] != "new"
      @user.relatives.find(attrs[:id])
    else
      User.new(
        responsible_id: @user.id,
        created_through: "user_relative_creation",
        organisation_ids: @user.organisation_ids
      )
    end
  end

  def saved_proches
    @saved_proches || []
  end

  def validate_ants_pre_demandes_count
    count = rdv_builder.ants_pre_demandes_count
    return if count.blank?

    errors.add(:base, "Veuillez choisir un nombre de pré-demandes entre 1 et 6") unless AntsPreDemandesCountValidator.count_valid?(count)
  end

  def validate_phone_number_present_for_motif_by_phone
    errors.add(:phone_number, :missing_for_phone_motif) if rdv.motif.phone? && user.phone_number.blank?
  end

  def create_rdv
    rdv_builder.rdv.collectif? ? create_collectif_participation : create_individual_rdv
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
