module Territories
  # Recalcule le statut "sensible" de tous les agents d'un espace dont l'admin vient d'activer ou de
  # désactiver l'obligation de double authentification, sans attendre CronJob::RefreshAgentsSensitiveAccountJob.
  # C'est notamment le seul moyen de repasser à false les agents qui n'étaient sensibles qu'à cause de cette
  # option : le job quotidien ne réévalue pas les agents sans rôle admin, accueil ou territorial.
  class RefreshAgentsSensitiveAccountJob < ApplicationJob
    def perform(territory)
      agents = Agent.where_id_in_subqueries([territory.organisations_agents, territory.roles.select(:agent_id)])

      agents.find_each do |agent|
        AgentSensitiveAccountCalculator.refresh_agent!(agent)
      end
    end
  end
end
