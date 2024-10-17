class Admin::Territories::AgentTerritorialAccessRightsController < Admin::Territories::BaseController
  def update
    agent = Agent.find(params[:id])
    agent_territorial_access_right = AgentTerritorialAccessRight.find_by(agent: agent, territory: current_territory)
    agent_territorial_access_right.assign_attributes(agent_territorial_access_right_params)
    authorize(agent_territorial_access_right, policy_class: Agent::AgentTerritorialAccessRightPolicy)

    agent_territorial_access_right.save!
    flash[:success] = "Droits d'accès mis à jour"
    redirect_to edit_admin_territory_agent_path(current_territory, agent)
  end

  def agent_territorial_access_right_params
    params.require(:agent_territorial_access_right).permit(:allow_to_manage_teams, :allow_to_manage_access_rights, :allow_to_invite_agents)
  end
end
