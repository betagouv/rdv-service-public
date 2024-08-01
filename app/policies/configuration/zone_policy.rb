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
    def initialize(context, scope)
      @current_agent = context.agent
      @scope = scope
    end

    def resolve
      @scope
        .joins(:sector)
        .where(sectors: { territory_id: @current_agent.territorial_roles.pluck(:territory_id) })
    end
  end
end
