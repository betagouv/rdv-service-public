class Admin::Territories::AgentTerritorialAccessRightsController < Admin::Territories::BaseController
  def update
    agent = Agent.find(params[:id])
    agent_territorial_access_right = AgentTerritorialAccessRight.find_or_initialize_by(agent: agent, territory: current_territory)
    policy = Agent::AgentTerritorialAccessRightPolicy.new(current_agent, agent_territorial_access_right)

    authorize(agent_territorial_access_right, policy_class: Agent::AgentTerritorialAccessRightPolicy)
    permitted_params = params.require(:agent_territorial_access_right).permit(*policy.permitted_attributes)
    agent_territorial_access_right.assign_attributes(permitted_params)

    if agent_territorial_access_right.save
      flash[:success] = "Droits d'accès mis à jour"
    else
      flash[:error] = agent_territorial_access_right.errors.full_messages.to_sentence
    end
    redirect_to edit_admin_territory_agent_path(current_territory, agent)
  end
end
