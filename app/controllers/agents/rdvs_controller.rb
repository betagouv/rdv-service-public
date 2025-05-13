class Agents::RdvsController < AgentAuthController
  def show
    @rdv = policy_scope(Rdv, policy_scope_class: Agent::RdvPolicy::Scope).find(params[:id])
    authorize(@rdv, policy_class: Agent::RdvPolicy)
    redirect_to admin_organisation_rdv_path(@rdv.organisation, @rdv)
  end

  private

  def pundit_user
    current_agent
  end
end
