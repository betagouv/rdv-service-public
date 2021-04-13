class Admin::AgentRolesController < AgentAuthController
  before_action :set_agent_role, :set_agent_removal_presenter

  def edit
    authorize(@agent_role)
  end

  def update
    authorize(@agent_role)
    if Admin::AgentRoleAndService.update_with(@agent_role, agent_role_params[:level], agent_role_params[:agent_attributes][:service_ids])
      redirect_to admin_organisation_agents_path(current_organisation), success: "Les permissions de l'agent ont été mises à jour"
    else
      render :edit
    end
  end

  private

  def agent_role_params
    params.require(:agent_role).permit(:level, agent_attributes: [service_ids: []])
  end

  def set_agent_role
    @agent_role = AgentRole.find(params[:id])
  end

  def set_agent_removal_presenter
    @agent_removal_presenter = AgentRemovalPresenter.new(@agent_role.agent, current_organisation)
  end
end
