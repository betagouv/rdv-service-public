class Agents::CaldavSyncController < AgentAuthController
  layout "application_agent_config"

  before_action :feature_flag_verification!

  def show
    skip_authorization
  end

  def update
    skip_authorization
    current_agent.assign_attributes(
      caldav_agenda_url: params[:caldav_agenda_url],
      caldav_username: params[:caldav_username],
      caldav_password: params[:caldav_password]
    )
    if caldav_config_ok?
      current_agent.save!
      Caldav::MassExportEventToCaldavJob.perform_later(current_agent)
    else
      flash[:alert] = "La connexion au calendrier a échoué. Veuillez vérifier vos informations et réessayer."
    end

    redirect_to agents_calendar_sync_caldav_sync_path
  end

  def destroy
    skip_authorization
    current_agent.update!(caldav_disconnect_in_progress: true)
    Caldav::MassDestroyEventsAndAbsencesJob.perform_later(current_agent)
    redirect_to agents_calendar_sync_caldav_sync_path
  end

  private

  def caldav_config_ok?
    # Pour vérifier la configuration Caldav, on tente de récupérer l'URL principale.
    current_agent.caldav_client.principal_url

    true
  rescue StandardError
    false
  end

  def pundit_user
    AgentContext.new(current_agent)
  end

  def feature_flag_verification!
    return if current_agent.feature_enabled?(Agent::FeatureFlags::CALDAV_SYNC)

    redirect_to agents_calendar_sync_path, alert: "Vous n’avez pas accès à cette fonctionnalité. Si vous pensez que c’est une erreur, contactez un administrateur."
  end
end
