class Users::RdvBookingForm
  include Users::UserFormConcern

  attr_reader :rdv_builder, :invitation_token, :rdv, :selected_users

  delegate :to_query, :motif, :service, to: :rdv_builder
  delegate :add_benign_error, :ignore_benign_errors, :relatives_attributes=, to: :user
  delegate :collectif?, :requires_ants_predemande_number?, to: :rdv

  validate :validate_selected_users_count
  validate :validate_phone_number_present_for_motif_by_phone

  def initialize(user:, rdv_builder:, domain:, user_attributes: {}, selected_users: ["current_user"])
    @user = user
    @rdv_builder = rdv_builder
    @rdv = rdv_builder.rdv
    @domain = domain
    @selected_users = selected_users
    singleton_class.include(Users::RdvBookingForm::AntsConcern) if requires_ants_predemande_number?
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

  def new_proches
    built = (@user.relatives.target || []).select(&:new_record?)
    extras_count = [selected_users_expected_count - built.size, 0].max
    built + extras_count.times.map { @user.relatives.build }
  end

  def selected_users_expected_count = 1

  def selectable_existing_relatives
    @user.relatives.sort_by(&:first_name)
  end

  private

  def selected_user = selected_users.first

  def filter_and_enrich_relatives_attributes(attrs)
    # on garde uniquement les nested attributes pour les nouveaux proches sélectionnés
    attrs
      .select { _1[:id].blank? }
      .select.with_index { |_r, idx| selected_users.include?("new_relative_#{idx}") }
      .map { _1.merge(created_through: "user_relative_creation") }
  end

  def validate_selected_users_count
    if selected_users.size != selected_users_expected_count
      errors.add(:base, selected_users_expected_count == 1 ? "Veuillez sélectionner un·e seul participant·e" : "Veuillez sélectionner #{selected_users_expected_count} participant·es")
    end
  end

  def validate_phone_number_present_for_motif_by_phone
    errors.add(:phone_number, :missing_for_phone_motif) if rdv.motif.phone? && user.phone_number.blank?
  end

  def create_individual_rdv
    @rdv = rdv_builder.creneau.build_rdv # TODO: ce comportement est extrêmement surprenant, à refacto avec le RdvBuilder
    @rdv.assign_attributes(users: selected_users_records, created_by: @user)
    @rdv.save!
    notifier = Notifiers::RdvCreated.new(@rdv, @user)
    notifier.perform
    @invitation_token = notifier.participations_tokens_by_user_id[@user.id]
  end

  def create_participation
    new_participation = Participation.new(rdv:, user: selected_users_records.first, created_by: @user)
    new_participation.create_and_notify!(@user)
    @invitation_token = new_participation.restricted_auth_token
  end

  def selected_users_records
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
