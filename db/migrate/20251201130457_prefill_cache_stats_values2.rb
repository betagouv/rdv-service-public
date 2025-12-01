class PrefillCacheStatsValues2 < ActiveRecord::Migration[8.0]
  def up
    Rails.cache.write("stats.both_instances.1_year.rdvs_count", 2_041_534)
    Rails.cache.write("stats.both_instances.1_year.active_organisations_count", 2_041_534)
    Rails.cache.write("stats.both_instances.1_month.rdvs_count", 192_270)
    Rails.cache.write("stats.both_instances.1_month.active_agents_count", 11_361)
  end
end
