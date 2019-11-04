class Agents::PermissionsController < DashboardAuthController
  respond_to :html, :json

  def edit
    @permission = Agent::Permission.new(agent: Agent.find(params[:id]))
    authorize(@permission)
    respond_right_bar_with @permission
  end

  def update
    @permission = Agent::Permission.new(agent: Agent.find(params[:id]))
    authorize(@permission)
    flash[:notice] = "Agent mis à jour" if @permission.update(permission_params)
    respond_right_bar_with @permission, location: organisation_agents_path(current_organisation)
  end

  private

  def permission_params
    params.require(:agent_permission).permit(:role, :service_id)
  end
end
