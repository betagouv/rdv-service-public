# frozen_string_literal: true

class Configuration::SectorPolicy
  def initialize(context, agent)
    @current_agent = context.agent
    @current_territory = context.territory
    @agent = agent
  end

  def territorial_admin?
    @current_agent.territorial_admin_in?(@current_territory)
  end

  alias display? territorial_admin?
  alias new? territorial_admin?
  alias create? territorial_admin?
  alias show? territorial_admin?
  alias edit? territorial_admin?
  alias update? territorial_admin?
  alias destroy? territorial_admin?

  class Scope
    def initialize(context, _scope)
      @current_territory = context.territory
    end

    def resolve
      Sector.where(territory: @current_territory)
    end
  end
end
