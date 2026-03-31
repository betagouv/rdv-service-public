WITH rdv_solidarites_lieux_actifs AS (
  SELECT
    lieux.organisation_id,
    organisations.name AS "organisation_name",
    lieux.latitude,
    lieux.longitude,
    count(rdvs.id) AS rdv_count_lieu,
    0 AS rdv_count_orga,
    'RDV Solidarités' AS type_organisation
  FROM
    rdvs.lieux
    LEFT JOIN rdvs.rdvs ON rdvs.lieu_id = lieux.id
    LEFT JOIN rdvs.organisations ON organisations.id = lieux.organisation_id
    LEFT JOIN rdvs.territories ON territories.id = organisations.territory_id
  WHERE
    lieux.availability = 'enabled'
    AND rdvs.created_at > (CURRENT_DATE - INTERVAL '1 month')
    AND territories.public_stats
  GROUP BY
    lieux.id,
    lieux.latitude,
    lieux.longitude,
    lieux.organisation_id,
    organisations.name
  HAVING count(rdvs.id) > 5
),
rdv_solidarites_orgas_actives AS (
  SELECT organisations.id,
    organisations.name,
    count(rdvs.id) AS rdv_count_orga
  FROM rdvs.organisations
    LEFT JOIN rdvs.rdvs ON rdvs.organisation_id = organisations.id
    LEFT JOIN rdvs.territories ON territories.id = organisations.territory_id
  WHERE rdvs.created_at > (CURRENT_DATE - INTERVAL '1 month')
    AND territories.public_stats
  GROUP BY organisations.id
  HAVING COUNT(rdvs.id) > 5
),
rdv_solidarites_lieux_des_orgas_actives AS (
  SELECT DISTINCT ON (o.id)
    o.id AS organisation_id,
    o.name AS organisation_name,
    lieux.latitude,
    lieux.longitude,
    0 AS rdv_count_lieu,
    rdv_count_orga,
    'RDV Solidarités' AS type_organisation
  FROM
    rdvs.lieux
    INNER JOIN rdv_solidarites_orgas_actives o ON lieux.organisation_id = o.id
  WHERE
    lieux.availability = 'enabled'
    AND lieux.organisation_id NOT IN (SELECT organisation_id FROM rdv_solidarites_lieux_actifs)
  ORDER BY o.id
),
rdv_service_public_lieux_actifs AS (
  SELECT
    lieux.organisation_id,
    organisations.name AS "organisation_name",
    lieux.latitude,
    lieux.longitude,
    count(rdvs.id) AS rdv_count_lieu,
    0 AS rdv_count_orga,
    CASE ants_connectable WHEN TRUE THEN 'Mairie' ELSE 'RDV Service Public' END AS type_organisation
  FROM
    rdvsp.lieux
    LEFT JOIN rdvsp.rdvs ON rdvs.lieu_id = lieux.id
    LEFT JOIN rdvsp.organisations ON organisations.id = lieux.organisation_id
    LEFT JOIN rdvsp.territories ON territories.id = organisations.territory_id
  WHERE
    lieux.availability = 'enabled'
    AND rdvs.created_at > (CURRENT_DATE - INTERVAL '1 month')
    AND territories.public_stats
  GROUP BY
    lieux.id,
    lieux.latitude,
    lieux.longitude,
    lieux.organisation_id,
    organisations.name,
    organisations.ants_connectable
  HAVING count(rdvs.id) > 5
),
rdv_service_public_orgas_actives AS (
  SELECT organisations.id,
    organisations.name,
    organisations.ants_connectable,
    count(rdvs.id) AS rdv_count_orga
  FROM rdvsp.organisations
    LEFT JOIN rdvsp.rdvs ON rdvs.organisation_id = organisations.id
    LEFT JOIN rdvsp.territories ON territories.id = organisations.territory_id
  WHERE rdvs.created_at > (CURRENT_DATE - INTERVAL '1 month')
    AND territories.public_stats
  GROUP BY organisations.id
  HAVING COUNT(rdvs.id) > 5
),
rdv_service_public_lieux_des_orgas_actives AS (
  SELECT DISTINCT ON (o.id)
    o.id AS organisation_id,
    o.name AS organisation_name,
    lieux.latitude,
    lieux.longitude,
    0 AS rdv_count_lieu,
    rdv_count_orga,
    CASE ants_connectable WHEN TRUE THEN 'Mairie' ELSE 'RDV Service Public' END AS type_organisation
  FROM
    rdvsp.lieux
    INNER JOIN rdv_service_public_orgas_actives o ON lieux.organisation_id = o.id
  WHERE
    lieux.availability = 'enabled'
    AND lieux.organisation_id NOT IN (SELECT organisation_id FROM rdv_service_public_lieux_actifs)
  ORDER BY o.id
), source AS (
    SELECT * FROM rdv_solidarites_lieux_actifs
    UNION ALL
    SELECT * FROM rdv_solidarites_lieux_des_orgas_actives
    UNION ALL
    SELECT * FROM rdv_service_public_lieux_actifs
    UNION ALL
    SELECT * FROM rdv_service_public_lieux_des_orgas_actives
)
SELECT organisation_name, type_organisation, latitude, longitude FROM source
