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
    # TODO: cette règle ici n’a pas de sens, le contexte du territoire est indispensable
    agent_territories.any? { Agent::TeamPolicy.allowed_to_manage_teams_in?(_1, @current_agent) }
  end

  def update_services?
    # NOTE: le service est à l’échelle de l’agent, ça aura donc un impact inter-territoires
    agent_territories.any? { self.class.allowed_to_manage_agents_in?(_1, @current_agent) }
  end

  def create?
    agent_territories.any? { self.class.allowed_to_invite_agents_in?(_1, @current_agent) }
  end

  private

  def agent_territories
    return Territory.joins(:organisations).where(organisations: { id: @agent.organisation_ids }) if @agent.new_record?

    # tous les territoires où l'agent cible est admin OU a un rôle dans une orga peu importe son niveau d’accès
    # on pourrait aussi implémenter cette méthode en passant par les agent_territorial_access_rights mais c’est
    # plus explicite de l’écrire comme ça
    Territory.where(id: @agent.territory_ids.union(@agent.territories_through_organisation_ids))
  end
end
