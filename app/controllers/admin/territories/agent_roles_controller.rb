class Admin::Territories::AgentRolesController < Admin::Territories::BaseController
  def update
    agent_role = AgentRole.find(params[:id])
    authorize_agent(agent_role)
    if agent_role.update(agent_role_params)
      flash[:success] = "Les permissions de l'agent ont été mises à jour"
    else
      flash[:error] = agent_role.errors.full_messages.join(", ")
    end

    redirect_to edit_admin_territory_agent_path(current_territory, agent_role.agent)
  end

  def create
    agent_role = AgentRole.new(agent_role_params)
    authorize_agent(agent_role)
    if agent_role.save
      flash[:success] = "Les permissions de l'agent ont été mises à jour"
    else
      flash[:error] = agent_role.errors.full_messages.join(", ")
    end

    redirect_to edit_admin_territory_agent_path(current_territory, agent_role.agent)
  end

  def destroy
    agent_role = AgentRole.find(params[:id])
    authorize_agent(agent_role)

    agent = Agent.find(agent_role.agent_id)
    organisation = Organisation.find(agent_role.organisation_id)
    removal_service = AgentRemoval.new(agent, organisation)

    if removal_service.valid?
      removal_service.remove!
      if agent.organisations.count >= 1
        redirect_to edit_admin_territory_agent_path(current_territory, agent_role.agent), notice: removal_service.confirmation_message
      else
        redirect_to admin_territory_agents_path(current_territory), notice: removal_service.confirmation_message
      end
    else
      redirect_to edit_admin_territory_agent_path(current_territory, agent_role.agent), flash: { error: removal_service.errors.full_messages.join }
    end
  end

  private

  def pundit_user
    current_agent
  end

  def agent_role_params
    params.require(:agent_role).permit(:access_level, :organisation_id, :agent_id)
  end
end
