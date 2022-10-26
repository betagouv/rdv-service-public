# frozen_string_literal: true

class Admin::Territories::AgentTerritorialAccessRightsController < Admin::Territories::BaseController
  def update
    agent = Agent.find(params[:id])
    agent_territorial_access_right = AgentTerritorialAccessRight.find_by(agent: agent, territory: current_territory)
    authorize agent_territorial_access_right
    agent_territorial_access_right.update(agent_territorial_access_right_params)
    flash[:success] = "Droits d'accès mis à jour"
    redirect_to edit_admin_territory_agent_path(current_territory, agent)
  end

  def agent_territorial_access_right_params
    params.require(:agent_territorial_access_right).permit(:allow_to_manage_teams, :allow_to_manage_access_rights, :allow_to_invite_agents, :allow_to_download_metrics)
  end
end
