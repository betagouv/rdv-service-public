class Users::RdvBookingForm
  include Users::UserFormConcern
  include ActiveModel::Validations::Callbacks

  attr_reader :rdv_builder, :invitation_token, :rdv, :selected_users

  delegate :to_query, :motif, :service, to: :rdv_builder
  delegate :add_benign_error, :ignore_benign_errors, :relatives_attributes=, to: :user
  delegate :collectif?, :requires_ants_predemande_number?, to: :rdv

  validate :validate_user # ordre important car user.valid? commence par vider les erreurs sur @user
  validate :validate_selected_users_count
  validate :validate_phone_number_present_for_motif_by_phone

  def initialize(user:, rdv_builder:, domain:, user_attributes: {}, selected_users: ["current_user"])
    @user = user
    @rdv_builder = rdv_builder
    @rdv = rdv_builder.rdv
    @domain = domain
    @selected_users = selected_users
    singleton_class.include(Users::RdvBookingForm::AntsConcern) if requires_ants_predemande_number?
    @user_attributes = user_attributes.symbolize_keys

    filter_and_prepare_relatives_attributes! if @user_attributes[:relatives_attributes].present?
    rewrite_selected_users_new_relatives_index!

    @user.assign_attributes(@user_attributes)
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

  def show_birth_date_field? = !signed_in_with_restricted_auth_token? && rdv.territory&.enable_birth_date_field?

  def show_ants_pre_demande_number_field? = false

  def show_logement_field? = rdv.territory.enable_logement_field

  def show_address_field? = !signed_in_with_restricted_auth_token? && rdv.territory.enable_address_field?

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

  def selected_users_params = selected_users.map { SelectedUserParam.parse(_1) }

  def selectable_existing_relatives
    @user.relatives.sort_by(&:first_name)
  end

  def ants_meeting_point_id = rdv_builder.lieu_id

  private

  def validate_user = user.valid?

  def filter_and_prepare_relatives_attributes!
    # garde uniquement les attributs des proches ayant été cochés et ajoute created_through pour les nouveaux
    new_relatives_attributes, existing_relatives_attributes = @user_attributes[:relatives_attributes].values.map(&:symbolize_keys).partition { _1[:id].blank? }
    @user_attributes[:relatives_attributes] = selected_users_params.filter_map do |param|
      if param.new_relative?
        new_relatives_attributes[param.index].merge(created_through: "user_relative_creation")
      elsif param.existing_relative?
        existing_relatives_attributes.find { _1[:id] == param.id }
      end
    end
  end

  def rewrite_selected_users_new_relatives_index!
    # lorsque les nouveaux proches 1-3-4 sont sélectionnés mais pas le 2, on force la sélection à 1-2-3
    # pour aligner avec le filtre fait dans filter_and_prepare_relatives_attributes!
    new_relatives_count = selected_users_params.count(&:new_relative?)
    @selected_users = selected_users_params
      .reject(&:new_relative?)
      .map(&:to_s)
      .append(*new_relatives_count.times.map { |i| "new_relative_#{i}" })
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

    Notifiers::RdvCreated.new(@rdv, @user).perform

    @invitation_token = @user.participation_for(@rdv).restricted_auth_token
  end

  def create_participation
    new_participation = Participation.new(rdv:, user: selected_users_records.first, created_by: @user)
    new_participation.create_and_notify!(@user)
    @invitation_token = new_participation.restricted_auth_token
  end

  def selected_users_records
    selected_users_params.map do |param|
      case param.type
      when :current_user
        @user
      when :existing_relative
        @user.relatives.find(param.id)
      when :new_relative
        @user.relatives.target.select(&:previously_new_record?)[param.index]
      end
    end
  end
end
