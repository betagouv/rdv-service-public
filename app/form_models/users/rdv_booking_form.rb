class Users::RdvBookingForm
  include Users::UserFormConcern

  attr_reader :rdv_wizard

  delegate :ants_pre_demande_number, to: :user
  delegate :to_query, :motif, :service, to: :rdv_wizard
  delegate :rdv, to: :rdv_wizard
  delegate :territory, :requires_ants_predemande_number?, to: :rdv

  def initialize(user:, rdv_wizard:, domain:)
    @user = user
    @rdv_wizard = rdv_wizard
    @domain = domain
  end

  def current_organisation = motif.organisation

  def show_birth_date_field? = !signed_in_with_invitation_token? && territory&.enable_birth_date_field?

  def show_ants_pre_demande_number_field? = requires_ants_predemande_number?

  def show_address_field? = !signed_in_with_invitation_token? && current_organisation.territory.enable_address_field?

  def phone_required? = motif.phone?

  def address_required? = motif.home?

  def address_value = user.address.nil? ? to_query[:where] : user.address

  def show_social_fields? = service.nil? || service.user_field_groups.include?(:social)

  def show_logement_field? = current_organisation.territory.enable_logement_field
end
