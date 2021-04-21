class Admin::InvitationsController < AgentAuthController
  def index
    @invited_agents = policy_scope(Agent)
      .joins(:organisations).where(organisations: { id: current_organisation.id })
      .invitation_not_accepted
      .created_by_invite
      .order(invitation_sent_at: :desc)
      .page(params[:page])
    @invited_agents = @invited_agents.search_by_text(params[:search]) if params[:search].present?
  end

  def reinvite
    @agent = policy_scope(Agent).find(params[:id])
    authorize(@agent)
    @agent.invite!
    redirect_to admin_organisation_invitations_path(current_organisation), notice: "Une nouvelle invitation a été envoyée à l'agent #{@agent.email}."
  end
end
