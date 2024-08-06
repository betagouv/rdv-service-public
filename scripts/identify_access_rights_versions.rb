# Les agents territorial_access rights sont créés dès qu'un agent est ajouté à une organisation d'un nouveau territoire
# donc c'est une bone manière de vérifier l'ajout d'un agent à un territoire ou une organisation
# Cette méthode ne marche que pour l'année écoulée
PaperTrail::Version.where.not(item_type: %w[AgentTerritorialRole AgentTerritorialAccessRight Agent AgentRole]).delete_all

privilege_creations = PaperTrail::Version.where(item_type: %w[AgentTerritorialRole AgentTerritorialAccessRight])
  .where(event: "create")
  .where(identified: false); nil

privilege_creations.where(whodunnit: nil).update_all(identified: true)
privilege_creations.where("whodunnit ilike '[Admin]%'").update_all(identified: true)
privilege_creations.where("whodunnit ilike '[SuperAdmin]%'").update_all(identified: true)

def parent_privilege?(privilege_creation_version)
  return true if privilege_creation_version.whodunnit.nil? # Si le whodunnit est nil, l'opération a été faite par un script

  return true if privilege_creation_version.whodunnit.start_with?("[Admin]")
  return true if privilege_creation_version.whodunnit.start_with?("[SuperAdmin]")

  agent_last_name = privilege_creation_version.whodunnit[/[A-Z][A-Z]+/]
  agent_first_name = privilege_creation_version.whodunnit.gsub(agent_last_name, "").gsub("[Agent]", "").strip

  agent = Agent.find_by(first_name: agent_first_name, last_name: agent_last_name)

  nathalie = Agent.find 12622
  if privilege_creation_version.whodunnit[nathalie.full_name]
    agent = nathalie
  end

  return false unless agent

  puts "Agent found"

  territory_id = privilege_creation_version.object_changes["territory_id"].last

  parent_territorial_role = AgentTerritorialRole.find_by(agent_id: agent.id, territory_id: territory_id)

  return false unless parent_territorial_role

  puts "Parent role found"

  # Les versions sur cette table ont été ajoutées dans une pr du 27/6/2023 https://github.com/betagouv/rdv-service-public/pull/3579
  parent_territorial_role_created_at = parent_territorial_role.versions.where(event: :create)&.first&.created_at || Date.new(2023, 6, 27)

  if parent_territorial_role_created_at < privilege_creation_version.created_at
    true
  end
end

privilege_creations.find_each do |privilege_creation|
  privilege_creation.update(identified: parent_privilege?(privilege_creation))
end

privilege_creations.where(item_type: "AgentTerritorialRole").find_each do |privilege_creation|
  privilege_creation.update(identified: parent_privilege?(privilege_creation))
end

puts "test"
