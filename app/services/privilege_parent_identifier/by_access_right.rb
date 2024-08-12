class PrivilegeParentIdentifier::ByAccessRightVersion
  def initialize(version, parent_agent)
    @version = version
    @parent_agent = parent_agent
  end

  def identified?
    # Jusqu'à https://github.com/betagouv/rdv-service-public/pull/4524/files, le droit allow_to_manage_access_rights suffisait pour créer un admin de territoire
    parent_territorial_access_rights = AgentTerritorialAccessRight.where("created_at < ?", @version.created_at)
      .where(allow_to_manage_access_rights: true).find_by(agent_id: @parent_agent.id, territory_id: territory_id)

    # versions qui ont toujours eu ces droits
    parent_territorial_access_rights = parent_territorial_access_rights.select do |access_rights|
      access_rights.versions.where(event: :update).map do |version|
        version.object_changes["allow_to_manage_access_rights"].blank?
      end
    end

    parent_territorial_access_rights.any?
  end
end
