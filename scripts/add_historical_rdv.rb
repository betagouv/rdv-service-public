# frozen_string_literal: true

territory = Territory.find(1)

puts "Ajoute des rendez-vous pour le territoire : #{territory.name}"

territory.organisations.where(id: [1]).each do |organisation|
  puts "- pour l'organisation : #{organisation.name}"

  100_000.times do
    Rdv.create!(
      duration_in_min: 30,
      starts_at: Time.zone.now - rand(1..365).days,
      motif_id: organisation.motifs.sample(1).first.id,
      lieu: organisation.lieux.sample(1).first,
      status: Rdv.statuses.keys.sample(1).first,
      organisation_id: organisation.id,
      agent_ids: [organisation.agents.sample(1).first.id],
      user_ids: [organisation.users.sample(1).first.id]
    )
  end
end
