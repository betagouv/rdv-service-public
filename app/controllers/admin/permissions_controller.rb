class Admin::PermissionsController < AgentAuthController
  def edit
    @permission = Agent::Permission.new(agent: Agent.find(params[:id]))
    authorize(@permission)
  end

  def update
    @permission = Agent::Permission.new(agent: Agent.find(params[:id]))
    authorize(@permission)
    if @permission.update(permission_params)
      redirect_to admin_organisation_agents_path(current_organisation), success: "Les permissions de l'agent ont été mises à jour"
    else
      render :edit
    end
  end

  private

  def permission_params
    params.require(:agent_permission).permit(:role)
  end
end
