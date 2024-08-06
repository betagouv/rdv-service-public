# Un décorateur autour de PaperTrail::Version dans le contexte de la recherche de l'origine de chaque création de permission
class PrivilegeParentIdentifier::PrivilegeVersion < SimpleDelegator
  def territory_id
    object_changes["territory_id"].last
  end
end
