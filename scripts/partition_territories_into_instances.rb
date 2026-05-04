# Exemple:
# rails runner scripts/partition_territories_into_instances.rb

Territory.where(instance: nil).find_each do |territory|
  if territory.admin_agents.all? { |agent| agent.email && VerifiedServicePublicDomainNames.verified?(agent.email) }
    territory.update(instance: "DINUM")
  elsif territory.operator
    territory.update(instance: "ANCT")
  elsif territory.organisations.any?(&:ants_connectable) # rubocop:disable Lint/DuplicateBranch
    territory.update(instance: "ANCT")
  elsif territory.admin_agents.any? { |agent| agent.applications.where(oauth_application: { name: ["La Coop de la médiation numérique", "Mon Suivi Social", "RDV Aide Numérique"] }) } # rubocop:disable Lint/DuplicateBranch
    territory.update(instance: "ANCT")
  end
end
