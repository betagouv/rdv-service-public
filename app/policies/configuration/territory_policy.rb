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

  class Scope < ApplicationPolicy::Scope
    include CurrentAgentInPolicyConcern

    def resolve
      territories_with_at_least_partial_access_rights = Territory.joins(:agent_territorial_access_rights).where(
        agent_territorial_access_rights: { agent_id: current_agent.id }
      ).where("allow_to_manage_teams OR allow_to_invite_agents OR allow_to_manage_access_rights")

      scope.where_id_in_subqueries([
                                     current_agent.territories,
                                     territories_with_at_least_partial_access_rights,
                                   ])
    end
  end
end
