# Détermine si le compte d'un agent est "sensible" (accès à un volume important de RDVs),
# ce qui déclenche une exigence de double authentification renforcée (cf. sessions_controller
# et pro_connect_controller). Utilisé à la fois par le job quotidien qui recalcule tous les
# agents (CronJob::RefreshAgentsSensitiveAccountJob) et par AdminCreatesAgent pour recalculer
# immédiatement le statut d'un agent au moment de son invitation, sans attendre le job du lendemain.
class AgentSensitiveAccountCalculator
  SENSITIVE_RDV_THRESHOLD = 5_000

  class << self
    def refresh_all!
      sensitive_ids = (sensitive_agent_role_ids + sensitive_territory_admin_ids + rdv_insertion_admin_agent_ids).uniq

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
      sensitive_agent_role_ids(agent_id: agent.id).any? ||
        sensitive_territory_admin_ids(agent_id: agent.id).any? ||
        rdv_insertion_admin_agent_ids(agent_id: agent.id).any?
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
    def sensitive_agent_role_ids(agent_id: nil)
      scope = AgentRole.where("access_level = 'admin' OR agent_accueil = true")
      scope = scope.where(agent_id: agent_id) if agent_id
      scope.joins(organisation: :rdvs)
        .group(:agent_id)
        .having("COUNT(rdvs.id) >= ?", SENSITIVE_RDV_THRESHOLD)
        .pluck(:agent_id)
    end

    def sensitive_territory_admin_ids(agent_id: nil)
      scope = AgentTerritorialRole.where(territory_id: sensitive_territory_ids)
      scope = scope.where(agent_id: agent_id) if agent_id
      scope.pluck(:agent_id)
    end

    # Un admin de territoire a accès à l'ensemble des organisations de son territoire,
    # le volume est donc cumulé sur toutes les organisations du territoire.
    def sensitive_territory_ids
      Territory.joins(organisations: :rdvs)
        .group("territories.id")
        .having("COUNT(rdvs.id) >= ?", SENSITIVE_RDV_THRESHOLD)
        .pluck(:id)
    end

    def rdv_insertion_admin_agent_ids(agent_id: nil)
      scope = AgentRole.access_level_admin
        .joins(:organisation)
        .where(organisations: { verticale: :rdv_insertion })
      scope = scope.where(agent_id: agent_id) if agent_id
      scope.distinct.pluck(:agent_id)
    end
  end
end
