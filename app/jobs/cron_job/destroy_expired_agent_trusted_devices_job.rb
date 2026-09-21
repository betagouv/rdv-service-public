class CronJob::DestroyExpiredAgentTrustedDevicesJob < CronJob
  def perform
    AgentTrustedDevice.where(expires_at: ...Time.zone.now).in_batches.delete_all
  end
end
