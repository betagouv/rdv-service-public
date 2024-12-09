class Admin::Territories::AgentRolesController < Admin::Territories::BaseController
  def update
    agent_role = AgentRole.find(params[:id])
    authorize(agent_role, policy_class: Agent::AgentRolePolicy)
    if agent_role.update(agent_role_params)
      flash[:success] = "Les permissions de l'agent ont été mises à jour"
    else
      flash[:error] = agent_role.errors.full_messages.join(", ")
    end

    redirect_to edit_admin_territory_agent_path(current_territory, agent_role.agent)
  end

  def create
    agent_role = AgentRole.new(agent_role_params)
    authorize(agent_role, policy_class: Agent::AgentRolePolicy)
    if agent_role.save
      flash[:success] = "Les permissions de l'agent ont été mises à jour"
    else
      flash[:error] = agent_role.errors.full_messages.join(", ")
    end

    redirect_to edit_admin_territory_agent_path(current_territory, agent_role.agent)
  end

  def destroy
    agent_role = AgentRole.find(params[:id])
    authorize(agent_role, policy_class: Agent::AgentRolePolicy)

    agent = Agent.find(agent_role.agent_id)
    organisation = Organisation.find(agent_role.organisation_id)
    removal_service = AgentRemoval.new(agent, organisation)

    if removal_service.valid?
      removal_service.remove!
      flash[:notice] = removal_service.confirmation_message
      if agent.organisations.count >= 1
        redirect_to edit_admin_territory_agent_path(current_territory, agent_role.agent)
      else
        redirect_to admin_territory_agents_path(current_territory)
      end
    else
      flash[:error] = removal_service.errors.full_messages.join
      redirect_to edit_admin_territory_agent_path(current_territory, agent_role.agent)
    end
  end

  private

  def agent_role_params
    params.require(:agent_role).permit(:access_level, :organisation_id, :agent_id)
  end
end
