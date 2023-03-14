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
    # utiliser AgentRemoval.new(@agent, current_organisation)
    agent_role = AgentRole.find(params[:id])
    authorize(agent_role)

    agent = Agent.find(agent_role.agent_id)
    organisation = Organisation.find(agent_role.organisation_id)
    removal_service = AgentRemoval.new(agent, organisation)

    if removal_service.upcoming_rdvs?
      redirect_to edit_admin_territory_agent_path(current_territory, agent_role.agent), flash: { error: t(".cannot_delete_because_of_rdvs") }

    else
      if agent.organisations.count > 1
        if agent.invitation_accepted_at.blank?
          redirect_to edit_admin_territory_agent_path(current_territory, agent_role.agent), notice: t(".invitation_deleted")
        elsif agent.deleted_at?
          redirect_to edit_admin_territory_agent_path(current_territory, agent_role.agent), notice: t(".agent_deleted")
        else
          redirect_to edit_admin_territory_agent_path(current_territory, agent_role.agent), notice: t(".agent_removed_from_org")
        end
      else
        redirect_to admin_territory_agents_path(current_territory), notice: t(".agent_removed_from_org")
      end
      removal_service.remove!
    end
  end

  private

  def agent_role_params
    params.require(:agent_role).permit(:level, :organisation_id, :agent_id)
  end
end
