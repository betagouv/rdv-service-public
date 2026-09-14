class Admin::Territories::AgentRolesController < Admin::Territories::BaseController
  def update
    agent_role = AgentRole.find(params[:id])
    authorize(agent_role, policy_class: Agent::AgentRolePolicy)
    # `agent_role_params` permet de changer `organisation_id`, mais `AgentRole#organisation_cannot_change`
    # bloque déjà toute modification de ce champ sur un enregistrement existant (voir agent_role_spec.rb).
    # `agent_id`/`access_level` ne sont pas utilisés par `territorial_admin_or_can_invite_agents?`, donc
    # une ré-authorization après coup ne changerait pas le verdict : pas besoin de la faire ici.
    if agent_role.update(agent_role_params) # rubocop:disable RdvServicePublic/PunditAuthorizeStaleAfterMutation
      flash[:success] = "Les permissions de l'agent ont été mises à jour"
    else
      flash[:error] = agent_role.errors.full_messages.join(", ")
    end

    redirect_to edit_admin_territory_agent_path(current_territory, agent_role.agent)
  end

  def create
    agent_role = AgentRole.new(agent_role_params)
    authorize(agent_role, policy_class: Agent::AgentRolePolicy)
    if agent_role.save
      flash[:success] = "Les permissions de l'agent ont été mises à jour"
    else
      flash[:error] = agent_role.errors.full_messages.join(", ")
    end

    redirect_to edit_admin_territory_agent_path(current_territory, agent_role.agent)
  end

  def destroy
    agent_role = AgentRole.find(params[:id])
    authorize(agent_role, policy_class: Agent::AgentRolePolicy)

    agent = Agent.find(agent_role.agent_id)
    organisation = Organisation.find(agent_role.organisation_id)
    removal_service = AgentRemoval.new(agent, organisation)

    if removal_service.valid?
      removal_service.remove!
      flash[:notice] = removal_service.confirmation_message
      if agent.organisations.count >= 1
        redirect_to edit_admin_territory_agent_path(current_territory, agent_role.agent)
      else
        redirect_to admin_territory_agents_path(current_territory)
      end
    else
      flash[:error] = removal_service.errors.full_messages.join
      redirect_to edit_admin_territory_agent_path(current_territory, agent_role.agent)
    end
  end

  private

  def agent_role_params
    params.require(:agent_role).permit(:access_level, :agent_accueil, :organisation_id, :agent_id)
  end
end
