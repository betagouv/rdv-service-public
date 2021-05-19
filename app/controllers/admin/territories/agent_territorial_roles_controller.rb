# frozen_string_literal: true

class Admin::Territories::AgentTerritorialRolesController < Admin::Territories::BaseController
  def index
    @roles = policy_scope_admin(AgentTerritorialRole)
      .where(territory: current_territory)
    @territory = current_territory
  end

  def new
    @role = AgentTerritorialRole.new(territory: current_territory)
    @possible_agents = policy_scope_admin(Agent)
      .includes(:territories)
      .to_a
      .reject { _1.territorial_admin_in?(current_territory) }
    authorize_admin(@role)
  end

  def create
    @role = AgentTerritorialRole.new(agent_territorial_role_params)
    authorize_admin(@role)
    if @role.save
      redirect_to(
        admin_territory_agent_territorial_roles_path(current_territory),
        flash: { success: "#{@role.agent.full_name} a été ajouté(e) en tant qu'administrateur du #{current_territory}" }
      )
    else
      render :new
    end
  end

  def destroy
    role = AgentTerritorialRole.find(params[:id])
    authorize_admin(role)
    if role.destroy
      flash[:success] = "#{role.agent.full_name} n'a plus le rôle d'administrateur du #{current_territory}"
    else
      flash[:error] = "Erreur lors du retrait du rôle d'administrateur du #{current_territory} pour #{role.agent.full_name}"
    end
    redirect_to admin_territory_agent_territorial_roles_path(current_territory)
  end

  private

  def agent_territorial_role_params
    params.require(:agent_territorial_role).permit(:agent_id, :territory_id)
  end
end
