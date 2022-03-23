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

  def show?
    territorial_admin? ||
      (@current_agent.access_rights_for_territory(@current_territory)&.allow_to_manage_teams? || false)
  end

  def display_sms_configuration?
    @current_territory.has_own_sms_provider? && territorial_admin?
  end

  alias display_user_fields_configuration? territorial_admin?
  alias update? territorial_admin?
  alias edit? territorial_admin?
  alias display_rdv_fields_configuration? territorial_admin?
end
