class CronJob::RefreshCachedStatsJob < CronJob
  class SuspiciousFigureError < StandardError; end

  def perform(keys: nil, force: false)
    @force = force

    return unless MetabaseApi.authentication_present?

    (keys || all_keys).each { refresh_stats_key(_1) }

    # on lève l’exception hors de la boucle pour permettre de remplir les autres valeurs
    raise SuspiciousFigureError, @suspicious_value.to_s if @suspicious_value

    Rails.logger.debug "🏁 done"
  end

  private

  def refresh_stats_key(key)
    query = File.read(File.join(queries_dir_path, "#{key}.sql"))
    previous_value = Rails.cache.fetch(key)

    Rails.logger.debug { "querying Metabase for #{key}…" }
    new_value = MetabaseApi.sql_query(query)[0]["c"]
      .gsub(/[, ]/, "") # Metabase sometimes splits thousands with spaces or commas 🤷
      .to_i
    Rails.logger.info "got #{key} = #{new_value}"

    if previous_value.nil? ||
       @force ||
       (new_value.to_f / previous_value).between?(0.1, 10) # des valeurs 10x plus hautes ou plus petites sont suspectes
      Rails.cache.write(key, new_value, expires_at: 30.days.from_now)
      Rails.logger.debug "✅ wrote to cache"
    else
      @suspicious_value = { key:, new_value:, previous_value: }
    end
  end

  def all_keys
    Dir.entries(queries_dir_path)
      .select { _1.end_with?(".sql") }
      .map { _1.gsub(/\.sql$/, "") }
  end

  def queries_dir_path
    @queries_dir_path ||= File.expand_path("refresh_cached_stats_queries", __dir__)
  end
end
