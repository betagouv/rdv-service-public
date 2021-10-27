# frozen_string_literal: true

class Admin::AgentsController < AgentAuthController
  respond_to :html, :json

  def index
    agents = policy_scope(Agent)
      .joins(:organisations).where(organisations: { id: current_organisation.id })
      .active.order_by_last_name
    @invited_agents = agents.invitation_not_accepted.created_by_invite
    @complete_agents = index_params[:search].present? ? agents.search_by_text(index_params[:search]) : agents
    @complete_agents = @complete_agents.complete
      .includes(:service, :roles, :organisations)
      .page(params[:page])
  end

  def search
    agents = policy_scope(Agent)
      .joins(:organisations).where(organisations: { id: current_organisation.id })
      .active.order_by_last_name.complete
    agents = agents.order_by_last_name.limit(10)
    @agents = agents.search_by_text(search_params[:term]) if search_params[:term].present?
    skip_authorization
  end

  def destroy
    @agent = policy_scope(Agent).find(params[:id])
    authorize(@agent)
    removal_service = AgentRemoval.new(@agent, current_organisation)
    if removal_service.upcoming_rdvs?
      redirect_to edit_admin_organisation_agent_role_path(current_organisation, @agent.role_in_organisation(current_organisation)), flash: { error: t(".cannot_delete_because_of_rdvs") }
    else
      removal_service.remove!
      if @agent.invitation_accepted_at.blank?
        redirect_to admin_organisation_invitations_path(current_organisation), notice: t(".invitation_deleted")
      elsif @agent.deleted_at?
        redirect_to admin_organisation_agents_path(current_organisation), notice: t(".agent_deleted")
      else
        redirect_to admin_organisation_agents_path(current_organisation), notice: t(".agent_removed_from_org")
      end
    end
  end

  private

  def index_params
    @index_params ||= begin
      index_params = params.permit(:search)
      index_params[:search] = clean_search_term(index_params[:search])
      index_params
    end
  end

  def search_params
    @search_params ||= begin
      search_params = params.permit(:term)
      search_params[:term] = clean_search_term(search_params[:term])
      search_params
    end
  end

  def clean_search_term(term)
    return nil if term.blank?

    I18n.transliterate(term)
  end
end
