# frozen_string_literal: true

class Admin::Territories::AgentTerritorialAccessRightsController < Admin::Territories::BaseController
  def update
    agent = Agent.find(params[:id])
    agent_territorial_access_right = AgentTerritorialAccessRight.find_by(agent: agent, territory: current_territory)
    authorize agent_territorial_access_right
    agent_territorial_access_right.update(agent_territorial_access_right_params)
    redirect_to admin_territory_agents_path(current_territory)
  end

  def agent_territorial_access_right_params
    params.require(:agent_territorial_access_right).permit(:allow_to_manage_teams)
  end
end
