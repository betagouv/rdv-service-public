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
    @permission.update(permission_params)
    respond_right_bar_with @permission, location: agents_path
  end

  private

  def permission_params
    params.require(:agent_permission).permit(:role, :service_id)
  end
end
