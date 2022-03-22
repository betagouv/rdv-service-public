# frozen_string_literal: true

class Configuration::TerritoryPolicy
  def initialize(context, territory)
    @current_agent = context.agent
    @current_territory = context.territory
    @territory = territory
  end

  def territorial_admin?
    @current_agent.territorial_admin_in?(@current_territory)
  end

  alias show? territorial_admin?
  alias update? territorial_admin?
  alias edit? territorial_admin?
  alias display_rdv_fields_configuration? territorial_admin?
end
