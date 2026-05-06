class Agents::PagesController < AgentAuthController
  layout "application"

  CONTACT_TEAM_URL = "https://rdv.anct.gouv.fr/motif/KNLKRbg9/presentation-rdv-service-public".freeze

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
      else
        result = ProConnectOnboardingRouter.new(current_agent, current_domain).call
        case result.action
        when :attached_as_admin
          redirect_to admin_organisation_planning_agenda_path(current_agent.organisations.first)
        when :contact_admin
          @needs_permission_from_admin = true
        when :signup_via_operator
          redirect_to agents_inscription_via_operateur_path(operator_name: result.operator_name, signup_url: result.signup_url)
        end
      end
    end
  end

  private

  def pundit_user
    current_agent
  end
end
