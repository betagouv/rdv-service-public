class Configuration::MotifPolicy
  def initialize(context, motif)
    @current_agent = context.agent
    @current_territory = context.territory
    @motif = motif
  end

  def agent_is_territory_admin?
    @motif.organisation.territory.in?(@current_agent.territories)
  end
  alias destroy? agent_is_territory_admin?

  class Scope
    def initialize(context, _scope)
      @current_territory = context.territory
    end

    def resolve
      Motif.where(organisation: @current_territory.organisations)
    end
  end
end
