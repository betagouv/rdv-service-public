class Agents::WebcalSyncController < AgentAuthController
  layout "application_agent_config"
  before_action { @active_agent_preferences_menu_item = :synchronisation }

  def show
    current_agent.update!(calendar_uid: new_calendar_uid) if current_agent.calendar_uid.nil?
    authorize current_agent
  end

  def update
    authorize current_agent
    current_agent.update!(calendar_uid: new_calendar_uid)
    redirect_to agents_calendar_sync_webcal_sync_path, flash: { notice: "Votre url de calendrier a été mise à jour." }
  end

  def pundit_user
    AgentContext.new(current_agent)
  end

  private

  def new_calendar_uid
    "#{current_agent.full_name.parameterize}-#{SecureRandom.uuid}"
  end
end
