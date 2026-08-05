class Admin::InvitationsController < AgentAuthController
  def reinvite
    @agent = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope).find(params[:id])
    authorize(@agent, policy_class: Agent::AgentPolicy)
    UnblockBrevoTransactionalContact.new(@agent.email).call
    @agent.invite!(current_agent, validate: false)
    flash[:success] = "Une nouvelle invitation a été envoyée à l'agent #{@agent.email}."
    redirect_to admin_organisation_agents_path(current_organisation)
  end
end
