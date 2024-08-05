class Configuration::AgentPolicy
  def initialize(context, agent)
    @current_agent = context.agent
    @agent = agent
  end

  def self.allowed_to_manage_agents_in?(territory, agent, sufficient_rights: %i[allow_to_manage_access_rights? allow_to_manage_teams? allow_to_invite_agents?])
    return true if agent.territorial_admin_in?(territory)

    access_rights = agent.access_rights_for_territory(territory)
    sufficient_rights.any? { access_rights&.send(_1) }
  end

  def edit?
    any_territory_allowed? %i[allow_to_manage_access_rights? allow_to_manage_teams? allow_to_invite_agents?]
  end

  def update_teams?
    any_territory_allowed? %i[allow_to_manage_access_rights? allow_to_manage_teams? allow_to_invite_agents?]
  end

  def update_services?
    any_territory_allowed? %i[allow_to_manage_access_rights? allow_to_manage_teams? allow_to_invite_agents?]
  end

  def create?
    any_territory_allowed? %i[allow_to_invite_agents]
  end

  alias new? create?

  private

  def any_territory_allowed?(sufficient_rights)
    Territory
      .where(id: @agent.territory_ids.union(@agent.territories_through_organisation_ids))
      .any? { self.class.allowed_to_manage_agents_in?(_1, @current_agent, sufficient_rights:) }
  end
end
