class Admin::AgentRolesController < AgentAuthController
  before_action :set_agent, :set_agent_removal_presenter

  def edit
    @agent_role = AgentRole.find(params[:id])
    authorize(@agent_role)
  end

  def update
    @agent_role = AgentRole.find(params[:id])
    authorize(@agent_role)
    if @agent_role.update(agent_role_params)
      redirect_to admin_organisation_agents_path(current_organisation), success: "Les permissions de l'agent ont été mises à jour"
    else
      render :edit
    end
  end

  private

  def agent_role_params
    params.require(:agent_role).permit(:level)
  end

  def set_agent
    @agent = Agent.find(params[:id])
  end

  def set_agent_removal_presenter
    @agent_removal_presenter = AgentRemovalPresenter.new(@agent, current_organisation)
  end
end
