# frozen_string_literal: true

# Renvoie les invitations pour les cnfs restant

agents = Agent.joins(:organisations)
  .where(organisations: { territory_id: 31 })
  .where(invitation_accepted_at: nil)
  .distinct
  .order("agents.id asc")
  .offset(300) # Les 300 premiers sont invités dans le batch 1

agents.find_each do |agent|
  agent.invite!(nil, validate: false)
  puts "Invitation envoyée pour #{agent.email}"
end
