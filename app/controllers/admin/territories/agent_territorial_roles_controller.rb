# frozen_string_literal: true

class Admin::Territories::AgentTerritorialRolesController < Admin::Territories::BaseController
  def index
    @roles = policy_scope(AgentTerritorialRole).where(territory: current_territory)
    @territory = current_territory
  end

  def new
    @role = AgentTerritorialRole.new(territory: current_territory)
    @possible_agents = policy_scope(Agent)
      .includes(:territories)
      .to_a
      .reject { _1.territorial_admin_in?(current_territory) }
    authorize @role
  end

  def create
    @role = AgentTerritorialRole.new(agent_territorial_role_params)
    authorize @role
    if @role.save
      redirect_to(
        admin_territory_agent_territorial_roles_path(current_territory),
        flash: { success: "#{@role.agent.full_name} a été ajouté(e) en tant qu'administrateur du #{current_territory}" }
      )
    else
      render :new
    end
  end

  def update
    role = AgentTerritorialRole.find(params[:id])
    authorize role
    if role.update(agent_territorial_role_params)
      redirect_to admin_territory_agents_path(current_territory)
    else
      redirect_to admin_territory_agent_path(current_territory, role.agent), flash: "errorrrrrr"
    end
  end

  def destroy
    role = AgentTerritorialRole.find(params[:id])
    authorize role
    if role.destroy
      flash[:success] = "#{role.agent.full_name} n'a plus le rôle d'administrateur du #{current_territory}"
    else
      flash[:error] = "Erreur lors du retrait du rôle d'administrateur du #{current_territory} pour #{role.agent.full_name}"
    end
    redirect_to admin_territory_agent_territorial_roles_path(current_territory)
  end

  private

  def agent_territorial_role_params
    params.require(:agent_territorial_role).permit(:agent_id, :territory_id,
                                                   :allow_to_invite_agents,
                                                   :allow_to_agents_access_right,
                                                   :allow_to_manage_sectorization,
                                                   :allow_to_manage_organisation,
                                                   :allow_to_manage_webhook,
                                                   :allow_to_manage_sms_provider,
                                                   :allow_to_manage_teams,
                                                   :allow_to_change_display_preferences,
                                                   :allow_to_update_entity_informations)
  end
end
