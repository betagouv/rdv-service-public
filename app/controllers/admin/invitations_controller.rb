class Admin::InvitationsController < AgentAuthController
  def index
    @invited_agents = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope)
      .joins(:organisations).where(organisations: { id: current_organisation.id })
      .invitation_not_accepted.where.not(invitation_sent_at: nil)
      .created_by_invite
      .page(page_number)
    @invited_agents = index_params[:search].present? ? @invited_agents.search_by_text(index_params[:search]) : @invited_agents.order(invitation_sent_at: :desc)
  end

  def reinvite
    @agent = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope).find(params[:id])
    authorize(@agent)
    @agent.invite!(current_agent, validate: false)
    redirect_to admin_organisation_invitations_path(current_organisation), notice: "Une nouvelle invitation a été envoyée à l'agent #{@agent.email}."
  end

  private

  def index_params
    @index_params ||= params.permit(:search)
  end
end
