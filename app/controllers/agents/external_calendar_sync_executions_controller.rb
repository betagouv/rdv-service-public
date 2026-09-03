class Agents::ExternalCalendarSyncExecutionsController < AgentAuthController
  layout "application_agent_config"
  before_action { @active_agent_preferences_menu_item = :synchronisation }

  def index
    @sync_executions = policy_scope(ExternalCalendarSyncExecution.all, policy_scope_class: Agent::ExternalCalendarSyncExecutionPolicy::Scope)
      .where(calendar_url: current_agent.caldav_config.caldav_agenda_url)
      .order(started_at: :desc)
      .includes(:logs)
      .page(page_number)
      .per(10)
  end

  private

  def pundit_user = current_agent
end
