class Agents::CalendarSyncController < AgentAuthController
  layout "application_agent_config"
  before_action { @active_agent_preferences_menu_item = :synchronisation }

  def show
    authorize(current_agent, policy_class: Agent::AgentPolicy)
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end
