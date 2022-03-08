# frozen_string_literal: true

class Configuration::AgentTerritorialRolePolicy
  def initialize(context, role)
    @context = context
    @role = role
  end

  def territorial_admin?
    @context.agent.territorial_admin_in?(@context.territory)
  end

  alias new? territorial_admin?
  alias create? territorial_admin?
  alias update? territorial_admin?
  alias destroy? territorial_admin?

  class Scope
    def initialize(context, _scope)
      @context = context
    end

    def resolve
      AgentTerritorialRole.where(territory: @context.territory)
    end
  end
end
