class Admin::AgentIntervenantsController < AgentAuthController
  respond_to :html, :json

  def update
    @agent = Agent.find(params[:id])
    authorize(@agent, policy_class: Agent::AgentPolicy)

    agent_role = @agent.roles.find_by(organisation: current_organisation)

    # Seul `last_name` est modifié, ce qui n'affecte pas `current_agent_or_admin_in_record_organisation?`
    # (basé sur l'identité de l'agent et son organisation, pas sur son nom).
    if agent_role.intervenant? && @agent.update(last_name: params[:agent][:last_name]) # rubocop:disable RdvServicePublic/PunditAuthorizeStaleAfterMutation
      flash[:success] = "Intervenant modifié avec succès."

      redirect_to admin_organisation_agents_path(current_organisation)
    else
      flash[:error] = @agent.errors.full_messages.uniq.join(", ")
      redirect_to edit_admin_organisation_agent_path(current_organisation, @agent)
    end
  end
end
