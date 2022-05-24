# frozen_string_literal: true

class Configuration::TeamPolicy
  def initialize(context, team)
    @current_agent = context.agent
    @current_territory = context.territory
    @team = team
  end

  def team_of_territory_and_allowed_to_manage_teams?
    @team.territory == @current_territory && allowed_to_manage_teams?
  end

  def allowed_to_manage_teams?
    @current_agent.access_rights_for_territory(@current_territory)&.allow_to_manage_teams? || false
  end

  alias new? team_of_territory_and_allowed_to_manage_teams?
  alias destroy? team_of_territory_and_allowed_to_manage_teams?
  alias edit? team_of_territory_and_allowed_to_manage_teams?
  alias update? team_of_territory_and_allowed_to_manage_teams?
  alias versions? team_of_territory_and_allowed_to_manage_teams?

  alias create? allowed_to_manage_teams?
  alias display? allowed_to_manage_teams?

  class Scope
    def initialize(context, _scope)
      @current_territory = context.territory
    end

    def resolve
      @current_territory.teams
    end
  end
end
