class Admin::PermissionsController < AgentAuthController
  before_action :set_agent, :set_agent_removal_presenter

  def edit
    @permission = Agent::Permission.new(agent: @agent)
    authorize(@permission)
  end

  def update
    @permission = Agent::Permission.new(agent: @agent)
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

  def set_agent
    @agent = Agent.find(params[:id])
  end

  def set_agent_removal_presenter
    @agent_removal_presenter = AgentRemovalPresenter.new(@agent, current_organisation)
  end
end
