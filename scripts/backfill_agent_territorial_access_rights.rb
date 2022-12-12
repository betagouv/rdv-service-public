# frozen_string_literal: true

# usage: rails runner scripts/backfill_agent_territorial_access_rights.rb
Agent.joins("left outer join agent_territorial_access_rights on agents.id = agent_territorial_access_rights.agent_id")
  .where(agent_territorial_access_rights: { id: nil })
  .find_each do |agent|
    AgentTerritorialAccessRight.create(agent: agent, territory: agent.organisations.first.territory)
  end
