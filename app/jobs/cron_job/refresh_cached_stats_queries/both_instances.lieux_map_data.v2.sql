WITH
  rdvs_tagmap AS (
    SELECT DISTINCT
      ON (organisations.id) organisations.id AS organisation_id,
      tags.name AS territory_tag_name
    FROM
      rdvs.organisations
      LEFT JOIN rdvs.territories ON rdvs.territories.id = rdvs.organisations.territory_id
      LEFT JOIN rdvs.territory_tags ON rdvs.territory_tags.territory_id = rdvs.territories.id
      LEFT JOIN rdvs.tags ON rdvs.tags.id = rdvs.territory_tags.tag_id
  ),
  rdvs_lieux_actifs AS (
    SELECT
      lieux.organisation_id,
      organisations.name AS "organisation_name",
      lieux.latitude,
      lieux.longitude,
      count(rdvs.id) AS rdv_count_lieu,
      0 AS rdv_count_orga,
      territory_tag_name
    FROM
      rdvs.lieux
      LEFT JOIN rdvs.rdvs ON rdvs.lieu_id = lieux.id
      LEFT JOIN rdvs.organisations ON rdvs.organisations.id = lieux.organisation_id
      LEFT JOIN rdvs_tagmap t ON t.organisation_id = rdvs.organisations.id
    WHERE
      lieux.availability = 'enabled'
      AND rdvs.created_at > (CURRENT_DATE - INTERVAL '1 month')
    GROUP BY
      lieux.id,
      lieux.latitude,
      lieux.longitude,
      lieux.organisation_id,
      organisations.name,
      territory_tag_name
    HAVING
      count(rdvs.id) > 5
  ),
  rdvs_orgas_actives AS (
    SELECT
      organisations.id,
      organisations.name,
      count(rdvs.id) AS "rdv_count_orga",
      territory_tag_name
    FROM
      rdvs.organisations
      LEFT JOIN rdvs.rdvs ON rdvs.organisation_id = organisations.id
      LEFT JOIN rdvs_tagmap t ON t.organisation_id = rdvs.organisations.id
    WHERE
      rdvs.created_at > (CURRENT_DATE - INTERVAL '1 month')
    GROUP BY
      organisations.id,
      territory_tag_name
    HAVING
      COUNT(rdvs.id) > 5
  ),
  rdvs_lieux_des_orgas_actives AS (
    SELECT DISTINCT
      ON (o.id) o.id AS organisation_id,
      o.name AS organisation_name,
      lieux.latitude,
      lieux.longitude,
      0 AS rdv_count_lieu,
      rdv_count_orga,
      territory_tag_name
    FROM
      rdvs.lieux
      INNER JOIN rdvs_orgas_actives o ON lieux.organisation_id = o.id
    WHERE
      lieux.availability = 'enabled'
      AND lieux.organisation_id NOT IN (
        SELECT
          organisation_id
        FROM
          rdvs_lieux_actifs
      )
    ORDER BY
      o.id
  ),
  rdvsp_tagmap AS (
    SELECT DISTINCT
      ON (organisations.id) organisations.id AS organisation_id,
      tags.name AS territory_tag_name
    FROM
      rdvsp.organisations
      LEFT JOIN rdvsp.territories ON rdvsp.territories.id = rdvsp.organisations.territory_id
      LEFT JOIN rdvsp.territory_tags ON rdvsp.territory_tags.territory_id = rdvsp.territories.id
      LEFT JOIN rdvsp.tags ON rdvsp.tags.id = rdvsp.territory_tags.tag_id
  ),
  rdvsp_lieux_actifs AS (
    SELECT
      lieux.organisation_id,
      organisations.name AS "organisation_name",
      lieux.latitude,
      lieux.longitude,
      count(rdvs.id) AS rdv_count_lieu,
      0 AS rdv_count_orga,
      territory_tag_name
    FROM
      rdvsp.lieux
      LEFT JOIN rdvsp.rdvs ON rdvs.lieu_id = lieux.id
      LEFT JOIN rdvsp.organisations ON rdvsp.organisations.id = lieux.organisation_id
      LEFT JOIN rdvsp_tagmap t ON t.organisation_id = rdvsp.organisations.id
    WHERE
      lieux.availability = 'enabled'
      AND rdvs.created_at > (CURRENT_DATE - INTERVAL '1 month')
    GROUP BY
      lieux.id,
      lieux.latitude,
      lieux.longitude,
      lieux.organisation_id,
      organisations.name,
      territory_tag_name
    HAVING
      count(rdvs.id) > 5
  ),
  rdvsp_orgas_actives AS (
    SELECT
      organisations.id,
      organisations.name,
      count(rdvs.id) AS "rdv_count_orga",
      territory_tag_name
    FROM
      rdvsp.organisations
      LEFT JOIN rdvsp.rdvs ON rdvs.organisation_id = organisations.id
      LEFT JOIN rdvsp_tagmap t ON t.organisation_id = rdvsp.organisations.id
    WHERE
      rdvs.created_at > (CURRENT_DATE - INTERVAL '1 month')
    GROUP BY
      organisations.id,
      territory_tag_name
    HAVING
      COUNT(rdvs.id) > 5
  ),
  rdvsp_lieux_des_orgas_actives AS (
    SELECT DISTINCT
      ON (o.id) o.id AS organisation_id,
      o.name AS organisation_name,
      lieux.latitude,
      lieux.longitude,
      0 AS rdv_count_lieu,
      rdv_count_orga,
      territory_tag_name
    FROM
      rdvsp.lieux
      INNER JOIN rdvsp_orgas_actives o ON lieux.organisation_id = o.id
    WHERE
      lieux.availability = 'enabled'
      AND lieux.organisation_id NOT IN (
        SELECT
          organisation_id
        FROM
          rdvsp_lieux_actifs
      )
    ORDER BY
      o.id
  ),
  source AS (
    SELECT * FROM rdvs_lieux_actifs
    UNION ALL
    SELECT * FROM rdvs_lieux_des_orgas_actives
    UNION ALL
    SELECT * FROM rdvsp_lieux_actifs
    UNION ALL
    SELECT * FROM rdvsp_lieux_des_orgas_actives
  )
SELECT
  organisation_name,
  territory_tag_name,
  latitude,
  longitude
FROM
  source
