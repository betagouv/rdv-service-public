class Admin::Territories::OrganisationsController < Admin::Territories::BaseController
  def index
    @organisations = organisations
  end

  def select_for_close
    @organisations = organisations
    authorize(@organisations.first, :close?, policy_class: Agent::OrganisationPolicy)
  end

  def close
    organisation = Organisation.find(params[:organisation_id])
    authorize(organisation, :close?, policy_class: Agent::OrganisationPolicy)

    flash[:success] = "L'organisation a été fermée."
    redirect_to admin_territory_organisations_path(organisation.territory)
  end

  private

  def organisations
    policy_scope(current_agent.organisations, policy_scope_class: Agent::OrganisationPolicy::Scope)
      .where(territory: current_territory)
      .ordered_by_name
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end
