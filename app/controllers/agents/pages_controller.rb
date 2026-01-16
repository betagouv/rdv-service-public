class Agents::PagesController < AgentAuthController
  layout "application"

  CONTACT_TEAM_URL = "https://cal.com/forms/937585aa-48a4-4efd-a642-961fad79c9c5".freeze

  def home
    skip_authorization

    accessible_organisations = policy_scope(Organisation, policy_scope_class: Agent::OrganisationPolicy::Scope)

    if accessible_organisations.count == 1
      redirect_to admin_organisation_planning_agenda_path(accessible_organisations.first)
    elsif accessible_organisations.count > 1
      redirect_to admin_organisations_path
    else
      policy = Agent::TerritoryPolicy.new(current_agent, Territory.new)
      if current_agent.possible_duplicate_organisations.empty? && policy.new?
        redirect_to new_agents_territory_path
      end
    end
  end

  private

  def pundit_user
    current_agent
  end
end
