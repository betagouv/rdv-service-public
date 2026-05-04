# Exemple:
# rails runner scripts/partition_territories_into_instances.rb

class Territory
  def dinum?
    admin_agents.all? { |agent| agent.email && VerifiedServicePublicDomainNames.verified?(agent.email) }
  end

  def anct?
    operator || organisations.any?(&:ants_connectable) || admin_agents.any? do |agent|
      agent.applications.where(oauth_applications: { name: ["La Coop de la médiation numérique", "Mon Suivi Social", "RDV Aide Numérique"] }).any?
    end
  end
end

Territory.where(instance: nil).find_each do |territory|
  if territory.dinum? && territory.anct?
    puts "Ambiguous territory: #{territory.id} #{territory.name_in_stats}"
    territory.update(instance: "BOTH")
  elsif territory.dinum?
    territory.update(instance: "DINUM")
  elsif territory.anct?
    territory.update(instance: "ANCT")
  end
end

puts Territory.group(:instance).count
