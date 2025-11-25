class CronJob::RefreshCachedStatsJob < CronJob
  class SuspiciousFigureError < StandardError; end

  def perform(force: false)
    return unless MetabaseApi.authentication_present?

    queries_by_key.each do |key, query|
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
        @suspicious_value = { key:, new_value:, previous_value: }
      end
    end

    # on lève l’exception hors de la boucle pour permettre de remplir les autres valeurs
    raise SuspiciousFigureError, @suspicious_value.to_s if @suspicious_value

    Rails.logger.debug "🏁 done"
  end

  private

  def queries_by_key
    {
      "stats.both_instances.2_years.rdvs_count" => <<~SQL.squish,
        SELECT
          SUM(c) AS c
        FROM
          (
            (
              SELECT
                COUNT("rdvsp".rdvs."id") AS c
              FROM
                "rdvsp"."rdvs"
              WHERE
                (
                  "rdvsp"."rdvs"."starts_at" >= CAST((NOW() + INTERVAL '-730 day') AS date)
                )
            )
            UNION ALL
            (
              SELECT
                COUNT("rdvs"."rdvs"."id") AS c
              FROM
                "rdvs"."rdvs"
              WHERE
                (
                  "rdvs"."rdvs"."starts_at" >= CAST((NOW() + INTERVAL '-730 day') AS date)
                )
            )
          );
      SQL
      "stats.both_instances.2_years.active_organisations_count" => <<~SQL.squish,
        SELECT
          SUM(c) AS c
        FROM
          (
            (
              SELECT
                COUNT(DISTINCT "rdvsp"."organisations"."id") AS c
              FROM
                "rdvsp"."organisations"
                INNER JOIN "rdvsp"."rdvs" ON "rdvsp"."rdvs"."organisation_id" = "rdvsp"."organisations"."id"
              WHERE
                (
                  "rdvsp"."rdvs"."starts_at" >= CAST((NOW() + INTERVAL '-730 day') AS date)
                )
            )
            UNION ALL
            (
              SELECT
                COUNT(DISTINCT "rdvs"."organisations"."id") AS c
              FROM
                "rdvs"."organisations"
                INNER JOIN "rdvs"."rdvs" ON "rdvs"."rdvs"."organisation_id" = "rdvs"."organisations"."id"
              WHERE
                (
                  "rdvs"."rdvs"."starts_at" >= CAST((NOW() + INTERVAL '-730 day') AS date)
                )
            )
          );
      SQL
    }
  end
end
