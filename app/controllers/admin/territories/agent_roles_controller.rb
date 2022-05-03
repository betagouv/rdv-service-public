# frozen_string_literal: true

class Admin::Territories::AgentRolesController < Admin::Territories::BaseController
  def edit
    authorize(@agent_role)
  end

  def update
    agent_role = AgentRole.find(params[:id])
    authorize(agent_role)
    if agent_role.update(agent_role_params)
      flash[:success] = "Les permissions de l'agent ont été mises à jour"
    end

    redirect_to edit_admin_territory_agent_path(current_territory, agent_role.agent)
  end

  def create
    agent_role = AgentRole.new(agent_role_params)
    authorize(agent_role)
    if agent_role.save
      flash[:success] = "Les permissions de l'agent ont été mises à jour"
    end

    redirect_to edit_admin_territory_agent_path(current_territory, agent_role.agent)
  end

  def destroy
    agent_role = AgentRole.find(params[:id])
    authorize(agent_role)
    if agent_role.destroy
      flash[:success] = "L'affectation à l'organisation #{agent_role.organisation.name} a bien été supprimée"
    end
    redirect_to edit_admin_territory_agent_path(current_territory, agent_role.agent)
  end

  private

  def agent_role_params
    params.require(:agent_role).permit(:level, :organisation_id, :agent_id)
  end
end
