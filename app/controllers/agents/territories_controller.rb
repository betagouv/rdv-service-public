class Agents::TerritoriesController < AgentAuthController
  layout "application"
  def new
    authorize(Territory.new, policy_class: Agent::TerritoryPolicy)
    @compte_form = Compte.new({}, current_domain)
  end

  def create
    authorize(Territory.new, policy_class: Agent::TerritoryPolicy)
    @compte_form = Compte.new(compte_params, current_domain)
    @compte_form.agent = current_agent

    if @compte_form.save!
      redirect_to admin_organisation_configuration_path(@compte_form.organisation)
    else
      render :new
    end
  end

  private

  def compte_params
    params[:compte][:agent] = {
      id: current_agent.id,
      service_ids: OauthApplication.default_service_ids_for(agent),
    }

    params.require(:compte).permit(
      territory: %i[name departement_number],
      organisation: %i[name],
      agent: [:id, { service_ids: [] }]
    )
  end

  def pundit_user
    current_agent
  end
end
