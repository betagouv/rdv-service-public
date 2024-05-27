class Configuration::MotifPolicy < Agent::MotifPolicy
  alias motif record

  def agent_is_territory_admin?
    motif.organisation.territory.in?(current_agent.territories)
  end

  alias show? agent_is_territory_admin?

  def current_agent
    pundit_user.agent
  end

  class Scope
    def initialize(context, _scope)
      @current_territory = context.territory
    end

    def resolve
      Motif.where(organisation: @current_territory.organisations)
    end
  end
end
