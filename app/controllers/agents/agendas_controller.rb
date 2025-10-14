class Agents::AgendasController < AgentAuthController
  def show
    skip_authorization # On appelle un policy_scope, donc pas besoin d'authorization

    accessible_organisations = policy_scope(Organisation, policy_scope_class: Agent::OrganisationPolicy::Scope)

    if accessible_organisations.count == 0
      redirect_to authenticated_agent_root_path
    elsif accessible_organisations.count == 1
      redirect_to admin_organisation_planning_agenda_path(accessible_organisations.first)
    elsif accessible_organisations.count > 1
      redirect_to admin_organisations_path
    end
  end

  private

  def pundit_user
    current_agent
  end
end
