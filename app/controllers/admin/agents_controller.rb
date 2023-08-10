# frozen_string_literal: true

class Admin::AgentsController < AgentAuthController
  respond_to :html, :json

  def index
    @agents = policy_scope(Agent)
      .includes(:service, :roles, :organisations)
      .active

    @agents = @agents.joins(:organisations).where(organisations: { id: current_organisation.id }) if current_organisation
    @invited_agents_count = @agents.invitation_not_accepted.created_by_invite.count

    @intervenants = index_params[:intervenant_term].present? ? @agents.intervenants.search_by_text(index_params[:intervenant_term]) : @agents.intervenants.order_by_last_name
    @intervenants = @intervenants.page(params[:intervenants_page])

    @agents = index_params[:term].present? ? @agents.not_intervenants.search_by_text(index_params[:term]) : @agents.not_intervenants.order_by_last_name
    @agents = @agents.complete.page(params[:page])
    @agents_and_intervenants = @agents + @intervenants
  end

  def destroy
    @agent = policy_scope(Agent).find(params[:id])
    authorize(@agent)
    removal_service = AgentRemoval.new(@agent, current_organisation)

    if removal_service.remove!
      if @agent.is_an_intervenant?
        redirect_to admin_organisation_agents_path(current_organisation), notice: "Intervenant supprimé avec succès."
      elsif @agent.invitation_accepted_at.blank?
        redirect_to admin_organisation_invitations_path(current_organisation), notice: removal_service.confirmation_message
      else
        redirect_to admin_organisation_agents_path(current_organisation), notice: removal_service.confirmation_message
      end
    else
      redirect_to edit_admin_organisation_agent_role_path(current_organisation, @agent.role_in_organisation(current_organisation)), flash: { error: removal_service.error_message }
    end
  end

  private

  def index_params
    @index_params ||= params.permit(:term, :intervenant_term)
  end
end
