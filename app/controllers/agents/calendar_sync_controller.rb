class Agents::CalendarSyncController < AgentAuthController
  include Admin::AuthenticatedControllerConcern

  layout "registration"
  before_action { @current_agent_settings_menu_entry = :synchronisation }

  def show
    authorize current_agent
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end
