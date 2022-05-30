# frozen_string_literal: true

# Renvoie les invitations pour 300 cnfs

agents = Agent.joins(:organisations)
  .where(organisations: { territory_id: 31 })
  .where(invitation_accepted_at: nil)
  .distinct
  .order("agents.id asc")
  .limit(300)

agents.find_each do |agent|
  agent.invite!(nil, validate: false)
  puts "Invitation envoyée pour #{agent.email}"
end
