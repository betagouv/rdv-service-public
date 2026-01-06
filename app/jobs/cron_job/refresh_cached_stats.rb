class CronJob::RefreshCachedStats
  class SuspiciousFigureError < StandardError; end

  QUERIES_DIR_PATH = File.expand_path("refresh_cached_stats_queries", __dir__).freeze

  KEYS_TO_FILENAME = {
    "stats.both_instances.1_year.rdvs_count" => "both_instances_1_year_rdvs_count.sql",
    "stats.both_instances.1_month.active_agents_count" => "both_instances_1_month_active_agents_count.sql",
    "stats.both_instances.1_month.active_organisations_count" => "both_instances_1_month_active_organisations_count.sql",
    "stats.both_instances.1_month.rdvs_count" => "both_instances_1_month_rdvs_count.sql",
    "stats.both_instances.lieux_map_data" => "both_instances.lieux_map_data.sql",
  }.freeze

  class EnqueueAllKeysJob < CronJob
    def perform(keys: nil, force: false)
      return unless MetabaseApi.authentication_present?

      (keys || KEYS_TO_FILENAME.keys).each { |key| RefreshKeyJob.perform_later(key:, force:) }
    end
  end

  class RefreshKeyJob < CronJob
    attr_reader :rows, :previous_value

    def capture_sentry_warning_for_retry?(_exception)
      # on ne souhaite pas être avertis avec un warning dès le premier retry,
      # un seul avertissement au 4è retry (arbitraire) suffit
      executions == 4
    end

    def perform(key:, force: false)
      filename = KEYS_TO_FILENAME[key]
      raise ArgumentError, "#{key} is not a valid stat key" if filename.nil?

      query = File.read(File.join(QUERIES_DIR_PATH, filename))
      @previous_value = Rails.cache.fetch(key)

      Rails.logger.debug { "querying Metabase for #{key}…" }
      @rows = MetabaseApi.sql_query(query)

      Rails.logger.debug { "values before and after #{values_to_compare}" }
      if previous_value.nil? || force || !suspicious_change?
        Rails.cache.write(key, new_value, expires_at: 30.days.from_now)
        Rails.logger.debug "✅ wrote to cache"
      else
        raise SuspiciousFigureError, { key:, values_to_compare: }.to_s
      end

      Rails.logger.debug "🏁 done"
    end

    private

    def suspicious_change?
      return false if values_to_compare.any?(&:nil?)

      ratio = values_to_compare[1].to_f / values_to_compare[0]
      ratio < 0.1 || ratio > 10
    end

    def new_value
      return rows unless single_count_row?

      # Metabase can split thousands with spaces or commas depending on its configurations, which can be changed in its web ui
      rows[0]["c"].gsub(/[, ]/, "").to_i
    end

    def single_count_row? = rows.count == 1 && rows[0]["c"].present?

    def values_to_compare
      single_count_row? ? [previous_value, new_value] : [previous_value&.count, rows.count]
    end
  end
end
