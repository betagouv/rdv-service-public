class Agent::TerritoryPolicy
  def initialize(current_agent, territory)
    @current_agent = current_agent
    @territory = territory
    @access_rights = @current_agent.agent_territorial_access_rights.find_by(territory_id: territory.id)
  end

  def territorial_admin?
    @current_agent.territorial_admin_in?(@territory)
  end

  alias manage_services? territorial_admin?
  alias update? territorial_admin?
  alias edit? territorial_admin?

  def new?
    return false if @current_agent.agent_territorial_access_rights.any?

    verified_by_email? || verified_by_proconnect_idp? || verified_by_partner_application?
  end
  alias create? new?

  def show?
    territorial_admin? ||
      allow_to_manage_teams? ||
      allow_to_manage_access_rights? ||
      allow_to_invite_agents?
  end

  def allow_to_manage_access_rights?
    @access_rights&.allow_to_manage_access_rights?
  end

  def allow_to_invite_agents?
    @access_rights&.allow_to_invite_agents?
  end

  def allow_to_manage_teams?
    @access_rights&.allow_to_manage_teams?
  end

  class Scope
    def initialize(current_agent, scope)
      @current_agent = current_agent
      @scope = scope
    end

    def resolve
      @scope.joins(:agent_territorial_access_rights)
        .where(agent_territorial_access_rights: { agent: @current_agent })
        .merge(AgentTerritorialAccessRight.with_some_rights_allowed)
    end
  end

  private

  def verified_by_partner_application?
    OauthApplication.agent_is_verified_by_an_application?(@current_agent)
  end

  def verified_by_email?
    VerifiedServicePublicDomainNames.verified?(@current_agent.email)
  end

  def verified_by_proconnect_idp?
    @current_agent.pro_connect_idp_id.in?(ProconnectIdentityProviders::ETAT)
  end
end
