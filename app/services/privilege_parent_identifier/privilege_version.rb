# Un décorateur autour de PaperTrail::Version dans le contexte de la recherche de l'origine de chaque création de permission
class PrivilegeParentIdentifier::PrivilegeVersion < SimpleDelegator
  def territory_id
    object_changes["territory_id"].last
  end

  def no_territory_privilege?
    item_type == "AgentRole" || (event == "create" && item_type == "AgentTerritorialAccessRight" && !access_right_changes?)
  end

  private

  def access_right_changes?
    (object_changes.keys & %w[
      allow_to_manage_access_rights
      allow_to_manage_teams
      allow_to_invite_agents
    ]).any? # array intersection
  end
end
