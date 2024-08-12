# Un décorateur autour de PaperTrail::Version dans le contexte de la recherche de l'origine de chaque création de permission
class PrivilegeParentIdentifier::PrivilegeVersion < SimpleDelegator
  def territory_id
    object_changes["territory_id"]&.last || organisation&.territory_id || organisation_version&.object["territory_id"]
  end

  def no_territory_privilege?
    item_type == "AgentRole" || (event == "create" && item_type == "AgentTerritorialAccessRight" && !access_right_changes?)
  end

  def agent
    Agent.find_by(id: object_changes["agent_id"].compact.last)
  end

  private

  def organisation
    @organisation ||= Organisation.find_by(id: organisation_id)
  end

  def organisation_id
    object_changes["organisation_id"].compact.last
  end

  def organisation_version
    PaperTrail::Version.find_by(item_type: "Organisation", item_id: organisation_id, event: :destroy)
  end

  def access_right_changes?
    (object_changes.keys & %w[
      allow_to_manage_access_rights
      allow_to_manage_teams
      allow_to_invite_agents
    ]).any? # array intersection
  end
end
