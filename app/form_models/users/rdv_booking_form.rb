class Users::RdvBookingForm
  include Users::UserFormConcern

  attr_reader :rdv_builder, :invitation_token, :rdv, :selected_users

  delegate :to_query, :motif, :service, to: :rdv_builder
  delegate :add_benign_error, :ignore_benign_errors, :relatives_attributes=, to: :user
  delegate :collectif?, to: :rdv

  validate :validate_selected_users_count
  validate :validate_phone_number_present_for_motif_by_phone

  def initialize(user:, rdv_builder:, domain:, user_attributes: {}, selected_users: ["current_user"])
    @user = user
    @rdv_builder = rdv_builder
    @rdv = rdv_builder.rdv
    @domain = domain
    @selected_users = selected_users
    singleton_class.include(Users::RdvBookingForm::AntsConcern) if @rdv.requires_ants_predemande_number?
    @user.singleton_class.accepts_nested_attributes_for :relatives
    user_attributes[:relatives_attributes] = filter_and_enrich_relatives_attributes(user_attributes.fetch(:relatives_attributes, {}).values.map(&:symbolize_keys))
    @user.assign_attributes(user_attributes)
  end

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      @user.save!
      rdv.collectif? ? create_participation : create_individual_rdv
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def show_birth_date_field? = !signed_in_with_invitation_token? && rdv.territory&.enable_birth_date_field?

  def show_ants_pre_demande_number_field? = false

  def show_logement_field? = rdv.territory.enable_logement_field

  def show_address_field? = !signed_in_with_invitation_token? && rdv.territory.enable_address_field?

  def address_required? = motif.home?

  def phone_required? = motif.phone?

  def address_value = user.address.nil? ? to_query[:where] : user.address

  def show_social_fields? = service.nil? || service.user_field_groups.include?(:social)

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

  def requires_ants_predemande_number? = false

  private

  def ants_with_multiple_pre_demandes? = false

  def selected_user = selected_users.first

  def filter_and_enrich_relatives_attributes(attrs)
    new_relative_index = -1
    attrs.select do |rel_attrs|
      if rel_attrs[:id].blank?
        new_relative_index += 1
        selected_users.include?("new_relative_#{new_relative_index}")
      end
    end.map do |rel_attrs|
      rel_attrs.merge(created_through: "user_relative_creation")
    end
  end

  def validate_selected_users_count
    if selected_users.size > 1 && !ants_with_multiple_pre_demandes?
      errors.add(:base, "Veuillez sélectionner un·e seul participant·e")
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
    selected_users.map do |selected_user|
      case selected_user
      when "current_user"
        @user
      when /existing_relative_(\d+)/
        @user.relatives.find(::Regexp.last_match(1))
      when /new_relative_(\d+)/
        @user.relatives.target.select(&:previously_new_record?)[::Regexp.last_match(1).to_i]
      end
    end
  end
end
