module Admin::AuthenticatedControllerConcern
  extend ActiveSupport::Concern

  included do
    rescue_from Pundit::NotAuthorizedError, with: :agent_not_authorized

    before_action :authenticate_agent!
    before_action :set_paper_trail_whodunnit
  end

  protected

  def user_for_paper_trail
    if current_super_admin.present?
      current_super_admin.name_for_paper_trail(impersonated: current_agent)
    else
      current_agent.name_for_paper_trail
    end
  end

  def agent_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    flash[:error] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
    redirect_to(request.referer || authenticated_agent_root_path)
  end
end
