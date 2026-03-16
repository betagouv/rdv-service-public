class CronJob::RefreshCartoANCTStatsJob < CronJob
  def perform
    CartoANCT.write_cache if ENV["CARTO_ANCT_SHARED_SECRET"]
  end
end
