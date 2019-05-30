class AgendasController < DashboardAuthController
  before_action :redirect_if_pro_incomplete, only: :index

  def index
    skip_policy_scope
  end

  private

  def redirect_if_pro_incomplete
    return unless pro_signed_in?

    redirect_to(new_pros_full_subscription_path) && return unless current_pro.complete?
    redirect_to(new_organisation_path) && return if current_pro.organisation.nil?
  end
end
