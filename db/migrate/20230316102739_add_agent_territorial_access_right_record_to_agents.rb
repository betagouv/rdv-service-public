# frozen_string_literal: true

class AddAgentTerritorialAccessRightRecordToAgents < ActiveRecord::Migration[7.0]
  def change
    Agent.where(deleted_at: nil).where.not(id: AgentTerritorialAccessRight.select(:agent_id)).each do |agent|
      agent.organisations.each do |organisation|
        AgentTerritorialAccessRight.find_or_create_by!(agent: agent, territory: organisation.territory)
      end
    end
  end
end
