class AgendasController < DashboardAuthController
  def index
    skip_policy_scope
  end
end
