class PrefillCacheStatsValues < ActiveRecord::Migration[7.2]
  def up
    Rails.cache.write("stats.both_instances.2_years.rdvs_count", 3675772)
    Rails.cache.write("stats.both_instances.2_years.organisations_count", 2403)
  end
end
