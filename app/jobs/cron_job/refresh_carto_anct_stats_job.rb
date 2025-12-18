class CronJob::RefreshCartoAnctStatsJob < CronJob
  def perform
    CartoAnct.write_cache
  end
end
