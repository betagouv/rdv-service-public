# The purpose of this script is to merge the data of 2 agents together.
# The source agent data will be merged into the destination agent data
# The script updates data from the following tables:
# absences
# agent_roles
# agent_teams
# agent_territorial_access_rights
# agent_territorial_roles
# agents_rdvs
# plage_ouvertures
# referent_assignations
# sector_attributions

# Usage: rails runner scripts/merge_two_agents.rb <source_id> <dest_id>

source_id = ARGV[0]
dest_id = ARGV[1]

source = Agent.find(source_id)
dest = Agent.find(dest_id)

if source.organisations.count > 1 || dest.organisations.count > 1
  puts "Both Agents must belong to only one organisation"
  exit 1
end

if source.organisations.ids != dest.organisations.ids
  puts "Both Agents must belong to the same organisation"
  exit 1
end

puts "Merging Agent(##{source.id} - #{source.email}) into Agent(##{dest.id} - #{dest.email})"

Agent.transaction do
  puts "---Merging Absences---"
  source.absences.update!(agent_id: dest.id)

  puts "---Merging Roles---"
  source_role = source.roles.first
  destination_role = dest.roles.first

  destination_role.destroy!
  source_role.update!(agent_id: dest.id)

  puts "---Merging Teams---"
  teams_to_add_to_destination = source.agent_teams.where.not(team_id: dest.teams.ids)

  teams_to_add_to_destination.update!(agent_id: dest.id)
  source.agent_teams.reload.destroy_all

  puts "---Merging Agent Rdvs---"
  source.agents_rdvs.update!(agent_id: dest.id)

  puts "---Merging Plage Ouvertures---"
  source.plage_ouvertures.update!(agent_id: dest.id)

  puts "---Merging Referent Assignations---"
  source.referent_assignations.update!(agent_id: dest.id)

  puts "---Merging Sector Attributions---"
  source.sector_attributions.update!(agent_id: dest.id)

  puts "---Deleting Source Agent---"

  Agent.find(source_id).destroy!

  puts "---Merge completed---"
end
