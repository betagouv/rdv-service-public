class Admin::Territories::AgentTerritorialRolesController < Admin::Territories::BaseController
  def create_or_destroy
    agent = Agent.find(params[:agent_id])
    access_right = AgentTerritorialAccessRight.find_or_initialize_by(territory: current_territory, agent: agent)
    authorize(access_right, policy_class: Agent::AgentTerritorialRolePolicy)

    access_right.full_rights = params[:territorial_admin] == "1"

    if access_right.save
      flash[:success] = if access_right.full_rights?
                          "Les droits d'administrateur du #{current_territory} ont été ajoutés à #{agent.full_name}"
                        else
                          "Les droits d'administrateur du #{current_territory} ont été retirés à #{agent.full_name}"
                        end
    else
      flash[:error] = access_right.errors.full_messages.to_sentence
    end

    redirect_to edit_admin_territory_agent_path(current_territory, agent)
  end

  def pundit_user
    current_agent
  end
end
