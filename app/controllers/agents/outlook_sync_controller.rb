# frozen_string_literal: true

class Agents::OutlookSyncController < AgentAuthController
  include Admin::AuthenticatedControllerConcern

  layout "registration"

  def show
    authorize current_agent
  end

  def destroy
    authorize current_agent, :current_agent_or_admin_in_record_organisation?
    Outlook::MassDestroyEventJob.perform_later(current_agent)
    flash[:notice] = "Votre compte Outlook est bien en cours de déconnexion. Cette action peut prendre plusieurs minutes, nécessaires à la suppression de votre événements dans votre agenda."
    redirect_to agents_calendar_sync_outlook_sync_path
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end
