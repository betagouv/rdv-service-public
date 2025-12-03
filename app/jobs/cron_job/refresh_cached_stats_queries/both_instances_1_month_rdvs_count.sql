SELECT
  count(*) as c
FROM
  (
    SELECT
      'rdvs' AS schema_name,
      starts_at
    FROM
      rdvs.rdvs
    UNION ALL
    SELECT
      'rdvsp' AS schema_name,
      starts_at
    FROM
      rdvsp.rdvs
  ) combined
WHERE
  starts_at >= (CURRENT_DATE - INTERVAL '30 days')
  AND starts_at < CURRENT_DATE
