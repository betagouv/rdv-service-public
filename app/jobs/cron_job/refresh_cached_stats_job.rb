class CronJob::RefreshCachedStatsJob < CronJob
  def perform
    return unless MetabaseApi.authentication_present?

    queries_by_key.each do |key, query|
      Rails.logger.debug { "querying Metabase for #{key}…" }
      count = MetabaseApi.sql_query(query)[0]["c"].gsub(",", "").to_i
      Rails.logger.info "got #{key} = #{count}. writing to cache…"
      Rails.cache.write(key, count, expires_at: 30.days.from_now)
      Rails.logger.debug "✅ wrote to cache"
    end
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
