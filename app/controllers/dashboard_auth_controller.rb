class DashboardAuthController < ApplicationController
  rescue_from Pundit::NotAuthorizedError, with: :agent_not_authorized

  before_action :authenticate_agent!

  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  helper_method :current_organisation

  private

  def pundit_user
    current_agent
  end

  def agent_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    flash[:error] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
    redirect_to(request.referrer || authenticated_agent_root_path)
  end

  def set_organisation
    @organisation = current_organisation
  end

  def current_organisation
    id = if params.require(:controller) == "organisations"
      params.require(:id)
    else
      params.require(:organisation_id)
    end
    policy_scope(Organisation).find(id)
  end
end
