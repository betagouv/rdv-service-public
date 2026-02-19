class CronJob::RefreshAgentsSensitiveAccountJob < CronJob
  SENSITIVE_TERRITORY_RDV_THRESHOLD = 10_000

  def perform
    sensitive_territory_ids = Territory.joins(:organisations)
      .joins("INNER JOIN rdvs ON rdvs.organisation_id = organisations.id")
      .group("territories.id")
      .having("COUNT(rdvs.id) >= ?", SENSITIVE_TERRITORY_RDV_THRESHOLD)
      .pluck(:id)

    territorial_admin_agent_ids = AgentTerritorialRole.distinct.pluck(:agent_id)
    sensitive_agent_ids = AgentTerritorialRole.where(territory_id: sensitive_territory_ids).pluck(:agent_id)

    # rubocop:disable Rails/SkipsModelValidations
    Agent.where(id: sensitive_agent_ids).in_batches.update_all(sensitive_account: true)
    Agent.where(id: territorial_admin_agent_ids).where.not(id: sensitive_agent_ids).in_batches.update_all(sensitive_account: false)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
