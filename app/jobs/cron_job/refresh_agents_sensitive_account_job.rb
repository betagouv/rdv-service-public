class CronJob::RefreshAgentsSensitiveAccountJob < CronJob
  SENSITIVE_TERRITORY_RDV_THRESHOLD = 5_000

  def perform
    return if disabled?

    sensitive_ids = (sensitive_territory_admin_ids + rdv_insertion_admin_agent_ids).uniq

    # rubocop:disable Rails/SkipsModelValidations
    Agent.where(id: sensitive_ids).in_batches.update_all(sensitive_account: true)
    Agent.where(id: territory_admin_ids).where.not(id: sensitive_ids).in_batches.update_all(sensitive_account: false)
    # rubocop:enable Rails/SkipsModelValidations
  end

  private

  def disabled?
    ENV["DISABLE_REFRESH_AGENTS_SENSITIVE_ACCOUNT_JOB"] == "true"
  end

  def territory_admin_ids
    AgentTerritorialAccessRight.where(full_rights: true).distinct.pluck(:agent_id)
  end

  def sensitive_territory_admin_ids
    AgentTerritorialAccessRight.where(full_rights: true, territory_id: sensitive_territory_ids).pluck(:agent_id)
  end

  def sensitive_territory_ids
    Territory.joins(organisations: :rdvs)
      .group("territories.id")
      .having("COUNT(rdvs.id) >= ?", SENSITIVE_TERRITORY_RDV_THRESHOLD)
      .pluck(:id)
  end

  def rdv_insertion_admin_agent_ids
    AgentRole.access_level_admin
      .joins(:organisation)
      .where(organisations: { verticale: :rdv_insertion })
      .distinct.pluck(:agent_id)
  end
end
