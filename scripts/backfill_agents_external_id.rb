# frozen_string_literal: true

# Usage :
# scalingo run "rails runner scripts/backfill_agents_external_id.rb.rb" --app production-rdv-solidarites --region osc-secnum-fr1
# A one-off script to backfill organisations.external_ids
# This script can be deleted after we run it once

# First thing we have to do is deduplicate some agents
ids_of_agents_to_delete = [7658, 7931, 8661, 9762, 9063, 10_469]

ids_of_agents_to_delete.each do |id|
  agent_to_delete = Agent.find(id)
  agent_to_delete.roles.first.delete
  agent_to_delete.soft_delete
end

# Now we can backfill
PaperTrail::Version.where(item_type: "Agent", event: "create").where("object_changes ilike '%conseiller-numerique.fr%'").find_each do |agent_version|
  original_agent = YAML.unsafe_load(agent_version.object_changes)
  agent = agent_version&.item
  if agent && !agent.deleted_at
    # rubocop:disable Rails::SkipsModelValidations
    agent.update_columns(external_id: original_agent["email"].presence&.last)
    # rubocop:enable Rails::SkipsModelValidations
  end
end
