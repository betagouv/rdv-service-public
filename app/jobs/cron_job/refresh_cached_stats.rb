class CronJob::RefreshCachedStats
  class SuspiciousFigureError < StandardError; end

  QUERIES_DIR_PATH = File.expand_path("refresh_cached_stats_queries", __dir__).freeze

  KEYS_TO_FILENAME = {
    "stats.both_instances.1_year.rdvs_count" => "both_instances_1_year_rdvs_count.sql",
    "stats.both_instances.1_month.active_agents_count" => "both_instances_1_month_active_agents_count.sql",
    "stats.both_instances.1_month.active_organisations_count" => "both_instances_1_month_active_organisations_count.sql",
    "stats.both_instances.1_month.rdvs_count" => "both_instances_1_month_rdvs_count.sql",

  }.freeze

  class EnqueueAllKeysJob < CronJob
    def perform(keys: nil, force: false)
      return unless MetabaseApi.authentication_present?

      (keys || KEYS_TO_FILENAME.keys).each { |key| RefreshKeyJob.perform_later(key:, force:) }
    end
  end

  class RefreshKeyJob < CronJob
    def perform(key:, force: false)
      filename = KEYS_TO_FILENAME[key]
      raise ArgumentError, "#{key} is not a valid stat key" if filename.nil?

      query = File.read(File.join(QUERIES_DIR_PATH, filename))
      previous_value = Rails.cache.fetch(key)

      Rails.logger.debug { "querying Metabase for #{key}…" }
      new_value = MetabaseApi.sql_query(query)[0]["c"]
        .gsub(/[, ]/, "") # Metabase can split thousands with spaces or commas depending on its configurations, which can be changed in its web ui
        .to_i
      Rails.logger.info "got #{key} = #{new_value}"

      if previous_value.nil? ||
         force ||
         (new_value.to_f / previous_value).between?(0.1, 10) # des valeurs 10x plus hautes ou plus petites sont suspectes
        Rails.cache.write(key, new_value, expires_at: 30.days.from_now)
        Rails.logger.debug "✅ wrote to cache"
      else
        raise SuspiciousFigureError, { key:, new_value:, previous_value: }.to_s
      end

      Rails.logger.debug "🏁 done"
    end
  end
end
