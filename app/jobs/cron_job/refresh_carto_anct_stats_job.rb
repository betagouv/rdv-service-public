class CronJob::RefreshCartoANCTStatsJob < CronJob
  def perform
    CartoANCT.write_cache
  end
end
