class Agents::CaldavSyncController < ApplicationController
  layout "application_agent_config"

  before_action :feature_flag_verification!

  def show; end

  private

  def feature_flag_verification!
    return if current_agent.feature_enabled?(Agent::FeatureFlags::CALDAV_SYNC)

    redirect_to agents_calendar_sync_path, alert: "Vous n’avez pas accès à cette fonctionnalité. Si vous pensez que c’est une erreur, contactez un administrateur."
  end
end
