class Configuration::ZonePolicy
  def initialize(context, zone)
    @current_agent = context.agent
    @zone = zone
  end

  def territorial_admin?
    @current_agent.territorial_admin_in?(@zone.territory)
  end

  alias new? territorial_admin?
  alias create? territorial_admin?
  alias destroy? territorial_admin?

  class Scope
    def initialize(context, _scope)
      @current_territory = context.territory
    end

    def resolve
      @current_territory.zones
    end
  end
end
