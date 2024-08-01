class Configuration::TerritoryPolicy
  def initialize(context, territory)
    @current_agent = context.agent
    @territory = territory
    @access_rights = @current_agent.access_rights_for_territory(@territory)
  end

  alias display_user_fields_configuration? territorial_admin?
  alias display_rdv_fields_configuration? territorial_admin?
  alias display_motif_fields_configuration? territorial_admin?
end
