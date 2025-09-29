class Agents::CaldavSyncController < ApplicationController
  layout "application_agent_config"

  before_action :feature_flag_verification!

  def show; end

  def update
    current_agent.update!(
      caldav_agenda_url: params[:caldav_agenda_url],
      caldav_username: params[:caldav_username],
      caldav_password: params[:caldav_password]
    )
    redirect_to agents_calendar_sync_caldav_sync_path
  end

  def destroy
    # TODO: À terme, il faudrait aussi supprimer les événements importés
    current_agent.update!(
      caldav_agenda_url: nil,
      caldav_username: nil,
      caldav_password: nil
    )
    redirect_to agents_calendar_sync_caldav_sync_path
  end

  private

  def feature_flag_verification!
    return if current_agent.feature_enabled?(Agent::FeatureFlags::CALDAV_SYNC)

    redirect_to agents_calendar_sync_path, alert: "Vous n’avez pas accès à cette fonctionnalité. Si vous pensez que c’est une erreur, contactez un administrateur."
  end
end
