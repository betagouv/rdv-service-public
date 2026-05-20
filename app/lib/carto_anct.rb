#
# Voir docs/interconnexions/carto_anct.md
#
module CartoANCT
  CACHE_KEY = "carto_anct_metrics".freeze

  def self.cached_metrics
    Rails.cache.read(CACHE_KEY)
  end

  def self.write_cache
    Rails.cache.write(CACHE_KEY, fetch_and_merge_metrics)
  end

  def self.fetch_and_merge_metrics
    siret_hash = Hash.new(0)

    nombre_agents_par_siret_espace(db_name: "rdvs").each  { |row| siret_hash[row["siret"]] += row["tu"].to_i }
    nombre_agents_par_siret_espace(db_name: "rdvsp").each { |row| siret_hash[row["siret"]] += row["tu"].to_i }

    siret_hash.sort.map { |siret, tu| { siret:, metrics: { tu: } } }
  end

  def self.nombre_agents_par_siret_espace(db_name:)
    query = <<~SQL.squish.gsub("$db_name", db_name)
      SELECT
        "$db_name"."territories"."siret" AS "siret",
        COUNT(DISTINCT "$db_name"."agents"."id") AS tu
      FROM
        "$db_name"."territories"
      JOIN
        "$db_name"."organisations" ON "$db_name"."organisations"."territory_id" = "$db_name"."territories"."id"
      JOIN
        "$db_name"."agent_roles" ON "$db_name"."agent_roles"."organisation_id" = "$db_name"."organisations"."id"
      JOIN
        "$db_name"."agents" ON "$db_name"."agents"."id" = "$db_name"."agent_roles"."agent_id"
      WHERE
        "$db_name"."territories"."siret" IS NOT NULL
      GROUP BY
        "$db_name"."territories"."siret";
    SQL
    MetabaseApi.sql_query(query, timeout: 60)
  end
end
