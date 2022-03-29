# frozen_string_literal: true

class Configuration::AgentTerritorialRolePolicy
  def initialize(context, role)
    @current_agent = context.agent
    @current_territory = context.territory
    @role = role
  end

  def territorial_admin?
    @current_agent.territorial_admin_in?(@current_territory)
  end

  alias display? territorial_admin?
  alias new? territorial_admin?
  alias create? territorial_admin?
  alias destroy? territorial_admin?

  class Scope
    def initialize(context, _scope)
      @current_territory = context.territory
    end

    def resolve
      AgentTerritorialRole.where(territory: @current_territory)
    end
  end
end
