class CronJob::RefreshCachedStats
  class SuspiciousFigureError < StandardError; end

  QUERIES_DIR_PATH = File.expand_path("refresh_cached_stats_queries", __dir__).freeze

  class EnqueueAllKeysJob < CronJob
    def perform(keys: nil, force: false)
      return unless MetabaseApi.authentication_present?

      (keys || all_keys).each { |key| RefreshKeyJob.perform_later(key:, force:) }
    end

    private

    def all_keys
      Dir.entries(QUERIES_DIR_PATH)
        .select { _1.end_with?(".sql") }
        .map { _1.gsub(/\.sql$/, "") }
    end
  end

  class RefreshKeyJob < CronJob
    def perform(key:, force: false)
      query = File.read(File.join(QUERIES_DIR_PATH, "#{key}.sql"))
      previous_value = Rails.cache.fetch(key)

      Rails.logger.debug { "querying Metabase for #{key}…" }
      new_value = MetabaseApi.sql_query(query)[0]["c"]
        .gsub(/[, ]/, "") # Metabase sometimes splits thousands with spaces or commas 🤷
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
