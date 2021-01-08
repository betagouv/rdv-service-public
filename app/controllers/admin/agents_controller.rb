class Admin::AgentsController < AgentAuthController
  respond_to :html, :json

  def index
    agents = policy_scope(Agent).active.order_by_last_name
    @invited_agents = agents.invitation_not_accepted.created_by_invite
    @complete_agents = params[:search].present? ? agents.search_by_text(params[:search]) : agents
    @complete_agents = @complete_agents.complete.includes(:service).page(params[:page])
  end

  def show
    @agent = policy_scope(Agent).find(params[:id])
    authorize(@agent)
    @status = params[:status]
    @organisation = current_organisation
    @selected_event_id = params[:selected_event_id]
    @date = params[:date].present? ? Date.parse(params[:date]) : nil
  end

  def destroy
    @agent = policy_scope(Agent).find(params[:id])
    authorize(@agent)
    removal_service = AgentRemoval.new(@agent, current_organisation)
    if removal_service.upcoming_rdvs?
      flash[:error] = "Impossible de retirer cet agent car il a des RDVs à venir dans cette organisation. Veuillez les supprimer ou les réaffecter avant de retirer cet agent."
      redirect_to edit_admin_organisation_permission_path(current_organisation, @agent)
    else
      removal_service.remove!
      if @agent.invitation_accepted_at.blank?
        flash[:notice] = "L'invitation a été supprimée"
        redirect_to admin_organisation_invitations_path(current_organisation)
      elsif @agent.deleted_at?
        flash[:notice] = "Le compte agent a été supprimé"
        redirect_to admin_organisation_agents_path(current_organisation)
      else
        flash[:notice] = "L'agent a été retiré de l'organisation"
        redirect_to admin_organisation_agents_path(current_organisation)
      end
    end
  end
end
