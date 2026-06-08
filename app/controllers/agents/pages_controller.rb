class Agents::PagesController < AgentAuthController
  layout "application"

  CONTACT_TEAM_URL = "https://rdv.anct.gouv.fr/motif/KNLKRbg9/presentation-rdv-service-public".freeze

  def home
    skip_authorization

    if current_domain == Domain::RDV_SERVICE_PUBLIC &&
       current_agent.organisations.exists? &&
       current_agent.organisations.all?(&:rdv_etat?)
      redirect_to authenticated_agent_root_url(host: Domain::RDV_SERVICE_PUBLIC_ETAT.host_name, automatic_redirection_from_rdvsp_anct: "1"), allow_other_host: true
      return
    end

    accessible_organisations = policy_scope(Organisation, policy_scope_class: Agent::OrganisationPolicy::Scope)

    if accessible_organisations.one?
      redirect_to admin_organisation_planning_agenda_path(accessible_organisations.first)
    elsif accessible_organisations.many?
      redirect_to admin_organisations_path
    else
      redirect_for_agent_without_organisation
    end
  end

  private

  def redirect_for_agent_without_organisation
    if Agent::TerritoryPolicy.new(current_agent, Territory.new).new?
      if current_agent.possible_duplicate_organisations.empty?
        redirect_to new_agents_territory_path
      end
    else
      redirect_via_anct_router
    end
  end

  def redirect_via_anct_router
    result = EspaceOperateurANCT::AccountCreationRouter.new(current_agent, current_domain).call
    case result.action
    when :attached_as_admin
      redirect_to admin_organisation_planning_agenda_path(current_agent.organisations.first)
    when :contact_admin
      @needs_permission_from_admin = true
    when :signup_via_operator
      session[:inscription_via_operateur] = { "operator_name" => result.operator_name, "signup_url" => result.signup_url }
      redirect_to agents_inscription_via_operateur_path
    end
  end

  def pundit_user
    current_agent
  end
end
