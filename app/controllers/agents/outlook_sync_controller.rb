# frozen_string_literal: true

class Agents::OutlookSyncController < AgentAuthController
  include Admin::AuthenticatedControllerConcern

  before_action :block_unauthorized_domains

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

  private

  def block_unauthorized_domains
    raise Pundit::NotAuthorizedError unless current_domain.can_sync_to_outlook
  end
end
