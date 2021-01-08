class Admin::InvitationsController < AgentAuthController
  def index
    @invited_agents = policy_scope(Agent).invitation_not_accepted.created_by_invite.order(invitation_sent_at: :desc)
  end

  def reinvite
    @agent = policy_scope(Agent).find(params[:id])
    authorize(@agent)
    @agent.invite!
    redirect_to admin_organisation_invitations_path(current_organisation), notice: "Une nouvelle invitation a été envoyée à l'agent #{@agent.email}."
  end
end
