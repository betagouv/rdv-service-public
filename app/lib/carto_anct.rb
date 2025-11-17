#
# Voir docs/interconnexions/carto_anct.md
#
module CartoAnct
  CACHE_KEY = "carto_anct_metrics".freeze

  def self.cached_metrics
    Rails.cache.read(CACHE_KEY)
  end

  def self.write_cache
    Rails.cache.write(CACHE_KEY, fetch_and_merge_metrics)
  end

  def self.fetch_and_merge_metrics
    insee_hash = Hash.new(0)
    siret_hash = Hash.new(0)

    nombre_agents_par_code_insee(db_name: "rdvs").each  { |row| insee_hash[row["insee"]] += row["tu"].to_i }
    nombre_agents_par_code_insee(db_name: "rdvsp").each { |row| insee_hash[row["insee"]] += row["tu"].to_i }
    nombre_agents_par_siret(db_name: "rdvs").each       { |row| siret_hash[row["siret"]] += row["tu"].to_i }
    nombre_agents_par_siret(db_name: "rdvsp").each      { |row| siret_hash[row["siret"]] += row["tu"].to_i }

    insee_metrics = insee_hash.sort.map { |insee, tu| { insee:, metrics: { tu: } } }
    siret_metrics = siret_hash.sort.map { |siret, tu| { siret:, metrics: { tu: } } }

    insee_metrics + siret_metrics
  end

  def self.nombre_agents_par_siret(db_name:)
    query = <<~SQL.squish.gsub(%("rdvsp"), %("#{db_name}"))
      SELECT
        "rdvsp"."agents"."proconnect_siret" AS "siret",
        COUNT(DISTINCT "rdvsp"."agents"."id") AS tu
      FROM
        "rdvsp"."agents"
      JOIN
        "rdvsp"."agents_rdvs" ON "rdvsp"."agents_rdvs"."agent_id" = "rdvsp"."agents"."id"
      JOIN
        "rdvsp"."rdvs" ON "rdvsp"."rdvs"."id" = "rdvsp"."agents_rdvs"."rdv_id"
      WHERE
        "rdvsp"."agents"."proconnect_siret" IS NOT NULL
      GROUP BY
        "rdvsp"."agents"."proconnect_siret";
    SQL
    MetabaseApi.sql_query(query, timeout: 60)
  end

  def self.nombre_agents_par_code_insee(db_name:)
    query = <<~SQL.squish.gsub(%("rdvsp"), %("#{db_name}"))
      SELECT
        "Correspondance Code Insee Code Postal - Code Postal"."code_insee" AS "insee",
        COUNT(DISTINCT "rdvsp"."agents"."id") AS "tu"
      FROM
        "rdvsp"."agents"

      JOIN "rdvsp"."agents_rdvs" AS "Agents Rdvs" ON "rdvsp"."agents"."id" = "Agents Rdvs"."agent_id"
        JOIN "rdvsp"."rdvs" AS "Rdvs" ON "Agents Rdvs"."rdv_id" = "Rdvs"."id"
        JOIN "rdvsp"."lieux" AS "Lieux - Lieu" ON "Rdvs"."lieu_id" = "Lieux - Lieu"."id"
        JOIN (
          SELECT
            "csv_uploads"."correspondance_code_insee_code_postal_20251105084418"."code_insee" AS "code_insee",
            "csv_uploads"."correspondance_code_insee_code_postal_20251105084418"."code_postal" AS "code_postal"
          FROM
            "csv_uploads"."correspondance_code_insee_code_postal_20251105084418"
        ) AS "Correspondance Code Insee Code Postal - Code Postal" ON "Lieux - Lieu"."code_postal" = "Correspondance Code Insee Code Postal - Code Postal"."code_postal"
      GROUP BY
        "Correspondance Code Insee Code Postal - Code Postal"."code_insee"
      ORDER BY
        "insee" ASC
    SQL
    MetabaseApi.sql_query(query, timeout: 60)
  end
end
