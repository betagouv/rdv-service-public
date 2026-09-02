class Agents::ExternalCalendarSyncLogsController < AgentAuthController
  layout "application_agent_config"
  before_action { @active_agent_preferences_menu_item = :synchronisation }

  def index
    @sync_logs = policy_scope(ExternalCalendarSyncLog.all, policy_scope_class: Agent::ExternalCalendarSyncLogPolicy::Scope)
      .where(calendar_url: current_agent.caldav_config.caldav_agenda_url)
      .order(started_at: :desc)
      .page(page_number)
      .per(10)
  end

  private

  def pundit_user
    current_agent
  end
end
