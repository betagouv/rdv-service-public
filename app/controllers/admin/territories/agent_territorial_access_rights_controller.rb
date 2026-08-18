class Admin::Territories::AgentTerritorialAccessRightsController < Admin::Territories::BaseController
  def update
    agent = Agent.find(params[:id])
    agent_territorial_access_right = AgentTerritorialAccessRight.find_or_initialize_by(agent: agent, territory: current_territory)
    policy = Agent::AgentTerritorialAccessRightPolicy.new(current_agent, agent_territorial_access_right)
    authorize(agent_territorial_access_right, policy_class: Agent::AgentTerritorialAccessRightPolicy)

    agent_territorial_access_right.assign_attributes(agent_territorial_access_right_params(policy))

    if agent_territorial_access_right.save
      flash[:success] = "Droits d'accès mis à jour"
    else
      flash[:error] = agent_territorial_access_right.errors.full_messages.to_sentence
    end
    redirect_to edit_admin_territory_agent_path(current_territory, agent)
  end

  private

  def agent_territorial_access_right_params(policy)
    permitted_keys = []
    permitted_keys += %i[allow_to_manage_teams allow_to_manage_access_rights allow_to_invite_agents] if policy.allow_to_manage_access_rights?
    permitted_keys << :full_rights if policy.edit_full_rights?

    params.require(:agent_territorial_access_right).permit(*permitted_keys)
  end
end
