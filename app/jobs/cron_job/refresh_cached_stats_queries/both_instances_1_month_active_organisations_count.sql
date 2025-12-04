SELECT
  SUM(subcount) AS c
FROM
  (
    (
      SELECT
        COUNT(DISTINCT "rdvsp"."organisations"."id") AS subcount
      FROM
        "rdvsp"."organisations"
        INNER JOIN "rdvsp"."rdvs" ON "rdvsp"."rdvs"."organisation_id" = "rdvsp"."organisations"."id"
      WHERE
        (
          "rdvsp"."rdvs"."starts_at" >= CAST((NOW() + INTERVAL '-30 day') AS date)
        )
    )
    UNION ALL
    (
      SELECT
        COUNT(DISTINCT "rdvs"."organisations"."id") AS subcount
      FROM
        "rdvs"."organisations"
        INNER JOIN "rdvs"."rdvs" ON "rdvs"."rdvs"."organisation_id" = "rdvs"."organisations"."id"
      WHERE
        (
          "rdvs"."rdvs"."starts_at" >= CAST((NOW() + INTERVAL '-30 day') AS date)
        )
    )
  );
