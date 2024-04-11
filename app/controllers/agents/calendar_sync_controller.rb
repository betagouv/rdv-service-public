class Agents::CalendarSyncController < AgentAuthController
  layout "registration"
  before_action { @active_agent_preferences_menu_item = :synchronisation }

  def show
    authorize current_agent
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end
