class Users::RdvBookingForm
  include Users::UserFormConcern

  attr_reader :rdv_wizard

  delegate :to_query, :motif, :service, :rdv, to: :rdv_wizard

  def initialize(user:, rdv_wizard:, domain:)
    @user = user
    @rdv_wizard = rdv_wizard
    @domain = domain
  end

  def show_birth_date_field? = !signed_in_with_invitation_token? && rdv.territory&.enable_birth_date_field?

  def show_ants_pre_demande_number_field? = rdv.requires_ants_predemande_number?

  def show_logement_field? = rdv.territory.enable_logement_field

  def show_address_field? = !signed_in_with_invitation_token? && rdv.territory.enable_address_field?

  def address_required? = motif.home?

  def phone_required? = motif.phone?

  def address_value = user.address.nil? ? to_query[:where] : user.address

  def show_social_fields? = service.nil? || service.user_field_groups.include?(:social)
end
