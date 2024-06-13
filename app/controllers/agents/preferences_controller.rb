class Agents::PreferencesController < AgentAuthController
  layout "application_agent_config"

  before_action { @active_agent_preferences_menu_item = :notifications }

  def show
    @agent = current_agent
    authorize @agent
  end

  def update
    @agent = current_agent
    authorize @agent

    if @agent.update(update_params)
      redirect_to agents_preferences_path, flash: { notice: t(".update.done") }
    else
      render :show
    end
  end

  def pundit_user
    AgentContext.new(current_agent)
  end

  def update_params
    params.require(:agent).permit(:rdv_notifications_level, :plage_ouverture_notification_level, :absence_notification_level)
  end
end
