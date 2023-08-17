# frozen_string_literal: true

class Admin::AgentIntervenantsController < AgentAuthController
  def update
    # Edit for intervenant is done in the role edit page for UX reasons
    @agent_intervenant = Agent.find(params[:id])
    authorize(@agent_intervenant)
    if @agent_intervenant.update(agent_intervenant_params)
      redirect_to admin_organisation_agents_path(current_organisation), notice: "Intervenant modifié avec succès."
    else
      redirect_to edit_admin_organisation_agent_role_path(current_organisation, @agent_intervenant.roles.first), flash: { error: @agent_intervenant.errors.full_messages.uniq.to_sentence }
    end
  end

  protected

  def set_services
    @services = services.order(:name)
  end

  def services
    Agent::ServicePolicy::AdminScope.new(pundit_user, Service).resolve
  end

  def pundit_user
    AgentOrganisationContext.new(current_agent, current_organisation)
  end

  def current_organisation
    Organisation.find(params[:organisation_id])
  end

  def agent_intervenant_params
    params.require(:agent).permit(:last_name, :service_id)
  end
end
