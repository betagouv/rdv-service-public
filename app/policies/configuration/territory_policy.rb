# frozen_string_literal: true

class Configuration::TerritoryPolicy
  def initialize(context, territory)
    @context = context
    @territory = territory
  end

  def territorial_admin?
    @context.agent.territorial_admin_in?(@context.territory)
  end

  alias show? territorial_admin?
  alias update? territorial_admin?
  alias edit? territorial_admin?
end
