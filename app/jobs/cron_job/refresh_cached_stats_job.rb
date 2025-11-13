class CronJob::RefreshCachedStatsJob < CronJob
  def perform
    total_rdvs_count = MetabaseApi.sql_query("SELECT (SELECT COUNT(*) FROM rdvs.rdvs) + (SELECT COUNT(*) FROM rdvsp.rdvs) as rdvs_count;")[0]["rdvs_count"].gsub(",", "").to_i
    Rails.logger.info "got #{total_rdvs_count} total RDV"
    Rails.cache.write("stats.both_instances.2_years.rdvs_count", total_rdvs_count)

    active_organisations_count = MetabaseApi.sql_query(
      <<~SQL.squish
        SELECT
          SUM(COUNT) AS "organisations_count"
        FROM
          (
            (
              SELECT
                COUNT(DISTINCT "rdvsp"."organisations"."id") AS COUNT
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
                COUNT(DISTINCT "rdvs"."organisations"."id") AS COUNT
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
    )[0]["organisations_count"].gsub(",", "").to_i
    Rails.logger.info "got #{active_organisations_count} active_organisations_count"
    Rails.cache.write("stats.both_instances.2_years.active_organisations_count", active_organisations_count)
  end
end
