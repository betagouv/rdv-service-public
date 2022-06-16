# frozen_string_literal: true

class Configuration::AgentRolePolicy
  def initialize(context, _agent)
    @current_agent = context.agent
    @current_territory = context.territory
    @access_rights = @current_agent.access_rights_for_territory(@current_territory)
  end

  def territorial_admin?
    @current_agent.territorial_admin_in?(@current_territory) ||
      @access_rights&.allow_to_invite_agents?
  end

  alias update? territorial_admin?
  alias edit? territorial_admin?
  alias create? territorial_admin?
  alias destroy? territorial_admin?
end
