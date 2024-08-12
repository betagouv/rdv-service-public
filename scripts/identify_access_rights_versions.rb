# Les agents territorial_access rights sont créés dès qu'un agent est ajouté à une organisation d'un nouveau territoire
# donc c'est une bone manière de vérifier l'ajout d'un agent à un territoire ou une organisation
# Cette méthode ne marche que pour l'année écoulée
PaperTrail::Version.where.not(item_type: %w[AgentTerritorialRole AgentTerritorialAccessRight Agent AgentRole Organisation]).delete_all

# gestion manuelle des accents dans un cas particulier
a = Agent.find_by(id: 17017)
if a
  a.update(first_name: a.first_name.gsub("re", "ré"))
end

a = Agent.find_by(id: 17350)
if a
  a.update(first_name: a.first_name.gsub("Lourdes ", ""))
end

privilege_creations = PaperTrail::Version.where(item_type: %w[AgentTerritorialRole AgentTerritorialAccessRight AgentRole])
  .where(event: "create")
  .where(identified: false); nil

privilege_creations.where(whodunnit: nil).update_all(identified: true)
privilege_creations.where("whodunnit ilike '[Admin]%'").update_all(identified: true)
privilege_creations.where("whodunnit ilike '[SuperAdmin]%'").update_all(identified: true)

privilege_creations.find_each do |privilege_creation|
  puts Time.zone.now
  identifer = PrivilegeParentIdentifier.new(privilege_creation)
  privilege_creation.update!(identified: identifer.parent_privilege?.to_b)
end

puts "test"
