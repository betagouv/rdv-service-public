class Admin::Territories::AgentTerritorialRolesController < Admin::Territories::BaseController
  def create_or_destroy
    agent = Agent.find(params[:agent_id])

    if params[:territorial_admin] == "1"
      create(agent)
    else
      destroy(agent)
    end
  end

  private

  def create(agent)
    role = AgentTerritorialRole.find_or_initialize_by(territory: current_territory, agent: agent)
    authorize(role, policy_class: Agent::RolePolicy)
    role.save!
    flash[:success] = "Les droits d'administrateur du #{current_territory} ont été ajoutés à #{agent.full_name}"

    redirect_to edit_admin_territory_agent_path(current_territory, agent)
  end

  def destroy(agent)
    role = AgentTerritorialRole.find_or_initialize_by(territory: current_territory, agent: agent)
    authorize(role, policy_class: Agent::RolePolicy)

    if !role.persisted? || role.destroy
      flash[:success] = "Les droits d'administrateur du #{current_territory} ont été retirés à #{agent.full_name}"
    else
      flash[:error] = role.errors.full_messages.to_sentence
    end
    redirect_to edit_admin_territory_agent_path(current_territory, agent)
  end

  def pundit_user
    current_agent
  end
end
