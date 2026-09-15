# Détermine si le compte d'un agent est "sensible" (accès à un volume important de RDVs),
# ce qui déclenche une exigence de double authentification renforcée (cf. sessions_controller
# et pro_connect_controller). Utilisé à la fois par le job quotidien qui recalcule tous les
# agents (CronJob::RefreshAgentsSensitiveAccountJob) et par AdminCreatesAgent pour recalculer
# immédiatement le statut d'un agent au moment de son invitation, sans attendre le job du lendemain.
class AgentSensitiveAccountCalculator
  SENSITIVE_RDV_THRESHOLD = 5_000

  class << self
    def refresh_all!
      sensitive_ids = (sensitive_agent_roles.pluck(:agent_id) + sensitive_territory_admins.pluck(:agent_id) + rdv_insertion_admin_agents.pluck(:agent_id)).uniq

      # rubocop:disable Rails/SkipsModelValidations
      Agent.where(id: sensitive_ids).in_batches.update_all(sensitive_account: true)
      Agent.where(id: evaluated_agent_ids).where.not(id: sensitive_ids).in_batches.update_all(sensitive_account: false)
      # rubocop:enable Rails/SkipsModelValidations
    end

    def refresh_agent!(agent)
      sensitive = sensitive?(agent)
      agent.update_column(:sensitive_account, sensitive) if agent.sensitive_account != sensitive # rubocop:disable Rails/SkipsModelValidations
    end

    def sensitive?(agent)
      sensitive_agent_roles.exists?(agent_id: agent.id) ||
        sensitive_territory_admins.exists?(agent_id: agent.id) ||
        rdv_insertion_admin_agents.exists?(agent_id: agent.id)
    end

    private

    # Tous les agents susceptibles d'être concernés par l'un des critères ci-dessous,
    # pour pouvoir repasser sensitive_account à false s'ils ne les remplissent plus.
    def evaluated_agent_ids
      (admin_or_agent_accueil_agent_ids + AgentTerritorialRole.distinct.pluck(:agent_id)).uniq
    end

    def admin_or_agent_accueil_agent_ids
      AgentRole.where("access_level = 'admin' OR agent_accueil = true").distinct.pluck(:agent_id)
    end

    # Un agent a accès à l'ensemble des RDVs d'une organisation (et non uniquement aux siens)
    # dès lors qu'il y a un rôle admin ou agent_accueil (cf. Agent::RdvPolicy::Scope). Le volume
    # est cumulé sur toutes les organisations où l'agent a un tel rôle.
    def sensitive_agent_roles
      AgentRole.where("access_level = 'admin' OR agent_accueil = true")
        .joins(organisation: :rdvs)
        .group(:agent_id)
        .having("COUNT(rdvs.id) >= ?", SENSITIVE_RDV_THRESHOLD)
    end

    def sensitive_territory_admins
      AgentTerritorialRole.where(territory_id: sensitive_territory_ids)
    end

    # Un admin de territoire a accès à l'ensemble des organisations de son territoire,
    # le volume est donc cumulé sur toutes les organisations du territoire.
    def sensitive_territory_ids
      Territory.joins(organisations: :rdvs)
        .group("territories.id")
        .having("COUNT(rdvs.id) >= ?", SENSITIVE_RDV_THRESHOLD)
        .pluck(:id)
    end

    def rdv_insertion_admin_agents
      AgentRole.access_level_admin
        .joins(:organisation)
        .where(organisations: { verticale: :rdv_insertion })
        .distinct
    end
  end
end
