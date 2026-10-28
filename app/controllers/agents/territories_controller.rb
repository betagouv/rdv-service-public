class Agents::TerritoriesController < AgentAuthController
  layout "application"
  def new
    authorize(Territory.new, policy_class: Agent::TerritoryPolicy)
    @compte_form = Compte.new({}, current_domain:)
  end

  def create
    authorize(Territory.new, policy_class: Agent::TerritoryPolicy)
    @compte_form = Compte.new(compte_params, current_domain:)
    @compte_form.agent = current_agent
    if current_agent.email&.ends_with?(".gouv.fr") && !VerifiedServicePublicDomainNames.france_service?(current_agent.email)
      @compte_form.territory.category = "État"
    end

    if @compte_form.save!
      CreateCrmPageJob.perform_later(@compte_form.territory.id) if @compte_form.territory.category.present?

      latest_rdv_plan = RdvPlan.where(planning_agent: current_agent).order("created_at desc").first

      if latest_rdv_plan
        redirect_to agents_rdv_plan_path(latest_rdv_plan)
      else
        redirect_to admin_organisation_configuration_path(@compte_form.organisation)
      end
    else
      render :new
    end
  end

  private

  def compte_params
    params[:compte][:agent] = {
      id: current_agent.id,
    }

    params.require(:compte).permit(
      territory: %i[name departement_number],
      organisation: %i[name],
      agent: [:id]
    )
  end

  def pundit_user
    current_agent
  end
end
