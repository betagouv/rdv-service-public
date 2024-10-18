class Agent::TeamPolicy
  def initialize(current_agent, team)
    @current_agent = current_agent
    @team = team
  end

  def update?
    self.class.allowed_to_manage_teams_in?(@team.territory, @current_agent)
  end

  def self.allowed_to_manage_teams_in?(territory, agent)
    agent.access_rights_for_territory(territory)&.allow_to_manage_teams?
  end

  alias new? update?
  alias create? update?
  alias edit? update?
  alias destroy? update?
  alias versions? update?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(territory_id: @pundit_user.agent_territorial_access_rights.select(:territory_id))
    end
  end
end
