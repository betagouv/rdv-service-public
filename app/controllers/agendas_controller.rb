class AgendasController < DashboardAuthController
  before_action :redirect_if_pro_incomplete, only: :index

  def index
    skip_policy_scope
    @organisation = current_pro.organisation

    rdvs = policy_scope(Rdv).includes(:evenement_type)
    @events = rdvs.map do |rdv|
      {
        title: rdv.name,
        start: rdv.start_at,
        end: rdv.end_at,
        allDay: false,
        url: rdv_path(rdv),
        backgroundColor: rdv.evenement_type&.color,
      }
    end
  end

  private

  def redirect_if_pro_incomplete
    return unless pro_signed_in?

    redirect_to(new_pros_full_subscription_path) && return unless current_pro.complete?
    redirect_to(new_organisation_path) && return if current_pro.organisation.nil?
  end
end
