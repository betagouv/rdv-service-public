class Users::RdvBookingForm
  include Users::UserFormConcern

  attr_reader :rdv_wizard

  delegate :to_query, :motif, :service, :rdv, to: :rdv_wizard

  def initialize(user:, rdv_wizard:, domain:)
    @user = user
    @rdv_wizard = rdv_wizard
    @domain = domain
  end
end
