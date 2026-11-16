module Territories
  # Recalcule le statut "sensible" de tous les agents d'un espace dont l'admin vient d'activer ou de
  # désactiver l'obligation de double authentification, sans attendre CronJob::RefreshAgentsSensitiveAccountJob.
  class RefreshAgentsSensitiveAccountJob < ApplicationJob
    def perform(territory)
      agents = Agent.where_id_in_subqueries([territory.organisations_agents, territory.roles.select(:agent_id)])

      agents.find_each do |agent|
        AgentSensitiveAccountCalculator.refresh_agent!(agent)
      end
    end
  end
end
