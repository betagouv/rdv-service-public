class Agents::PagesController < AgentAuthController
  layout "application"

  def home
    skip_authorization

    accessible_organisations = policy_scope(Organisation, policy_scope_class: Agent::OrganisationPolicy::Scope)

    if accessible_organisations.count == 1
      redirect_to admin_organisation_agent_agenda_path(accessible_organisations.first, current_agent)
    elsif accessible_organisations.count > 1
      redirect_to agents_organisations_path
    end
  end

  private

  def pundit_user
    AgentContext.new(current_agent)
  end
end
