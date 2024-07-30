class Configuration::TerritoryPolicy
  def initialize(context, territory)
    @current_agent = context.agent
    @territory = territory
    @access_rights = @current_agent.access_rights_for_territory(@territory)
  end

  def territorial_admin?
    @current_agent.territorial_admin_in?(@territory)
  end

  def show?
    territorial_admin? ||
      allow_to_manage_teams? ||
      allow_to_manage_access_rights? ||
      allow_to_invite_agents?
  end

  def allow_to_manage_access_rights?
    @access_rights&.allow_to_manage_access_rights?
  end

  def allow_to_invite_agents?
    @access_rights&.allow_to_invite_agents?
  end

  def allow_to_manage_teams?
    @access_rights&.allow_to_manage_teams?
  end

  alias display_user_fields_configuration? territorial_admin?
  alias update? territorial_admin?
  alias edit? territorial_admin?
  alias display_rdv_fields_configuration? territorial_admin?
  alias display_motif_fields_configuration? territorial_admin?
end
