class Agents::CaldavSyncController < AgentAuthController
  layout "application_agent_config"

  before_action :feature_flag_verification!

  def show
    authorize(current_agent, policy_class: Agent::AgentPolicy)
  end

  def update
    authorize(current_agent, policy_class: Agent::AgentPolicy)
    current_agent.update!(
      caldav_agenda_url: params[:caldav_agenda_url],
      caldav_username: params[:caldav_username],
      caldav_password: params[:caldav_password]
    )
    redirect_to agents_calendar_sync_caldav_sync_path
  end

  def destroy
    authorize(current_agent, policy_class: Agent::AgentPolicy)
    # TODO: À terme, il faudrait aussi supprimer les événements importés
    current_agent.update!(
      caldav_agenda_url: nil,
      caldav_username: nil,
      caldav_password: nil
    )
    redirect_to agents_calendar_sync_caldav_sync_path
  end

  private

  def pundit_user
    AgentContext.new(current_agent)
  end

  def feature_flag_verification!
    return if current_agent.feature_enabled?(Agent::FeatureFlags::CALDAV_SYNC)

    redirect_to agents_calendar_sync_path, alert: "Vous n’avez pas accès à cette fonctionnalité. Si vous pensez que c’est une erreur, contactez un administrateur."
  end
end
