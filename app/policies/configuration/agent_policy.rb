class Configuration::AgentPolicy
  def initialize(context, agent)
    @current_agent = context.agent
    @agent = agent
  end

  def self.allowed_to_manage_agents_in?(territory, agent)
    return true if agent.territorial_admin_in?(territory)

    access_rights = agent.access_rights_for_territory(territory)
    access_rights&.allow_to_manage_access_rights? ||
      access_rights&.allow_to_manage_teams? ||
      access_rights&.allow_to_invite_agents?
  end

  def self.allowed_to_invite_agents_in?(territory, agent)
    return true if agent.territorial_admin_in?(territory)

    agent.access_rights_for_territory(territory)&.allow_to_invite_agents?
  end

  def edit?
    agent_territories.any? { self.class.allowed_to_manage_agents_in?(_1, @current_agent) }
  end

  def update_teams?
    # TODO: cette règle ici n’a pas beaucoup de sens, le contexte du territoire est indispensable
    agent_territories.any? { Agent::TeamPolicy.allowed_to_manage_teams_in?(_1, @current_agent) }
  end

  def update_services?
    # NOTE: le service est à l’échelle de l’agent, ça aura donc un impact inter-territoires
    agent_territories.any? { self.class.allowed_to_manage_agents_in?(_1, @current_agent) }
  end

  def create?
    agent_territories.any? && # on ne peut pas créer d’agent non rattaché à un territoire
      agent_territories.all? { self.class.allowed_to_invite_agents_in?(_1, @current_agent) } # NOTE: on fait ici un all? et pas un any?
  end

  private

  def agent_territories
    # tous les territoires où l'agent cible est admin OU a un rôle dans une orga (basic, admin ou intervenant)
    # cette implémentation est plus explicite que via les agent_territorial_access_rights
    # passer par territory_ids et organisation_ids permet de supporter les tests sur les agents non persistés
    arel = Territory.left_joins(:organisations)
    arel.where(id: @agent.territory_ids).or(
      arel.where(organisations: { id: @agent.organisation_ids })
    )
  end
end
