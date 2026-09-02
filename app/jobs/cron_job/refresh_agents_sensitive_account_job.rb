class CronJob::RefreshAgentsSensitiveAccountJob < CronJob
  SENSITIVE_RDV_THRESHOLD = 5_000

  def perform
    return if disabled?

    sensitive_ids = (sensitive_agent_role_ids + sensitive_territory_admin_ids + rdv_insertion_admin_agent_ids).uniq

    # rubocop:disable Rails/SkipsModelValidations
    Agent.where(id: sensitive_ids).in_batches.update_all(sensitive_account: true)
    Agent.where(id: evaluated_agent_ids).where.not(id: sensitive_ids).in_batches.update_all(sensitive_account: false)
    # rubocop:enable Rails/SkipsModelValidations
  end

  private

  def disabled?
    ENV["DISABLE_REFRESH_AGENTS_SENSITIVE_ACCOUNT_JOB"] == "true"
  end

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
  def sensitive_agent_role_ids
    AgentRole.where("access_level = 'admin' OR agent_accueil = true")
      .joins(organisation: :rdvs)
      .group(:agent_id)
      .having("COUNT(rdvs.id) >= ?", SENSITIVE_RDV_THRESHOLD)
      .pluck(:agent_id)
  end

  def sensitive_territory_admin_ids
    AgentTerritorialRole.where(territory_id: sensitive_territory_ids).pluck(:agent_id)
  end

  # Un admin de territoire a accès à l'ensemble des organisations de son territoire,
  # le volume est donc cumulé sur toutes les organisations du territoire.
  def sensitive_territory_ids
    Territory.joins(organisations: :rdvs)
      .group("territories.id")
      .having("COUNT(rdvs.id) >= ?", SENSITIVE_RDV_THRESHOLD)
      .pluck(:id)
  end

  def rdv_insertion_admin_agent_ids
    AgentRole.access_level_admin
      .joins(:organisation)
      .where(organisations: { verticale: :rdv_insertion })
      .distinct.pluck(:agent_id)
  end
end
