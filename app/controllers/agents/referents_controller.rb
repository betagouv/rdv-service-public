class Agents::ReferentsController < AgentAuthController
  before_action :set_organisation, only: [:create]

  def create
    user = policy_scope(User).find(params[:id])
    flash[:error] = "Erreur lors de la modification des référents" unless user.update(agents: Agent.where(id: params[:user][:agent_ids]))
    redirect_to organisation_user_path(current_organisation, user)
  end
end
