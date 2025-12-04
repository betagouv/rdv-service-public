SELECT
  count(*) AS c
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
  starts_at >= (CURRENT_DATE - INTERVAL '1 years')
  AND starts_at < CURRENT_DATE
;
