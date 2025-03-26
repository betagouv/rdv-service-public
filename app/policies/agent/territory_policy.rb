class Agent::TerritoryPolicy
  def initialize(current_agent, territory)
    @current_agent = current_agent
    @territory = territory
    @access_rights = @current_agent.agent_territorial_access_rights.find_by(territory_id: territory.id)
  end

  def territorial_admin?
    @current_agent.territorial_roles.exists?(territory_id: @territory.id)
  end

  alias update? territorial_admin?
  alias edit? territorial_admin?

  def new?
    return false if @current_agent.agent_territorial_access_rights.any?

    self.class.verified_by_mss?(@current_agent)
  end
  alias create? new?

  # On espère que cette méthode est temporaire, et qu'on pourra ouvrir ça aux autres applications oauth
  def self.verified_by_mss?(agent)
    mss_oauth_application = Doorkeeper::Application.find_by(name: "Mon Suivi Social")
    agent.access_tokens.find_by(application_id: mss_oauth_application&.id)
  end

  def self.default_service(agent)
    # Pour le moment on propose cette fonctionnalité uniquement pour MSS, donc on met uniquement le service social
    if verified_by_mss?(agent)
      Service.find_by!(name: "Action Sociale")
    else
      raise NotImplementedError, <<~MSG
        Il faut définir les services par défaut pour les applications autre que mss, ou permettre le fonctionnement sans service (ni pour les agents ni pour les motifs)
        (voir https://github.com/betagouv/rdv-service-public/pull/5182)"
      MSG
    end
  end

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
      territories_with_roles = @scope.joins(:roles)
        .where(agent_territorial_roles: { agent: @current_agent })

      territories_with_rights = @scope.joins(:agent_territorial_access_rights)
        .where(agent_territorial_access_rights: { agent: @current_agent })
        .merge(AgentTerritorialAccessRight.with_some_rights_allowed)

      @scope.where_id_in_subqueries([territories_with_roles, territories_with_rights])
    end
  end
end
