class CronJob::RefreshCartoANCTStatsJob < CronJob
  def perform
    CartoANCT.write_cache if ENV["CARTO_ANCT_ENABLED"]
  end
end
