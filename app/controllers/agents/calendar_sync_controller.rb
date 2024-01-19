class Agents::CalendarSyncController < AgentAuthController
  include Admin::AuthenticatedControllerConcern

  layout "agent_settings"

  def show
    authorize current_agent
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end
