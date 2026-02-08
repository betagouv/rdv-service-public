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
end
