class Agent::TeamPolicy
  def initialize(current_agent, team)
    @current_agent = current_agent
    @team = team
  end

  def self.allowed_to_manage_teams_in?(territory, agent)
    agent.access_rights_for_territory(territory)&.allow_to_manage_teams?
  end

  def update?
    allowed_to_manage_teams? && agents_in_team_territory?
  end

  alias new? update?
  alias create? update?
  alias edit? update?
  alias destroy? update?
  alias versions? update?

  private

  def allowed_to_manage_teams?
    self.class.allowed_to_manage_teams_in?(@team.territory, @current_agent)
  end

  def agents_in_team_territory?
    @team.agents.all? { |agent| agent.territories_through_organisations.include?(@team.territory) }
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(territory_id: @pundit_user.agent_territorial_access_rights.select(:territory_id))
    end
  end
end
