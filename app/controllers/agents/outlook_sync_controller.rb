class Agents::OutlookSyncController < AgentAuthController
  include Admin::AuthenticatedControllerConcern

  layout "application_agent_config"
  before_action { @active_agent_preferences_menu_item = :synchronisation }

  def show
    authorize(current_agent, policy_class: Agent::AgentPolicy)
  end

  def destroy
    authorize(current_agent, :current_agent_or_admin_in_record_organisation?, policy_class: Agent::AgentPolicy)
    current_agent.update!(outlook_disconnect_in_progress: true)
    Outlook::MassDestroyEventJob.perform_later(current_agent)
    flash[:notice] = "Votre compte Outlook est bien en cours de déconnexion. " \
                     "Cette action peut prendre plusieurs minutes, nécessaires à la suppression de vos événements dans votre agenda. " \
                     "Rechargez la page un peu plus tard pour voir l'état de la déconnexion."
    redirect_to agents_calendar_sync_outlook_sync_path
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end
