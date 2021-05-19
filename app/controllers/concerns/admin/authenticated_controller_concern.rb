# frozen_string_literal: true

module Admin::AuthenticatedControllerConcern
  extend ActiveSupport::Concern

  included do
    rescue_from Pundit::NotAuthorizedError, with: :agent_not_authorized

    before_action :authenticate_agent!
    before_action :set_paper_trail_whodunnit
    helper_method :authorize_admin
    helper_method :policy_scope_admin
  end

  def authorize_admin(record, *args, **kwargs)
    authorize([:agent, record], *args, **kwargs)
  end

  def policy_scope_admin(clasz, *args, **kwargs)
    policy_scope([:agent, clasz], *args, **kwargs)
  end

  protected

  def user_for_paper_trail
    current_agent.name_for_paper_trail
  end

  def agent_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    flash[:error] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
    redirect_to(request.referer || authenticated_agent_root_path)
  end
end
