# Exemple:
# rails runner scripts/partition_territories_into_instances.rb

class Territory
  def dinum?
    admin_agents.all? { |agent| agent.email && VerifiedServicePublicDomainNames.verified?(agent.email) } ||
      admin_agents.any? { |agent| agent.pro_connect_idp_id.in?(ProconnectIdentityProviders::ETAT) }
  end

  def anct?
    operator || organisations.any?(&:ants_connectable) || admin_agents.any? do |agent|
      agent.applications.where(oauth_applications: { name: ["La Coop de la médiation numérique", "Mon Suivi Social", "RDV Aide Numérique"] }).any?
    end ||
      admin_agents.any? { |agent| agent.pro_connect_idp_id.in?(ProconnectIdentityProviders::COLLECTIVITES) }
  end
end

Territory.update_all(instance: nil)
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

Territory.where(instance: nil, category: "État").map do |t|
  t.admin_agents.pluck(:email).map do |e|
    (e || "").split("@").last
  end.uniq
end.flatten.uniq
