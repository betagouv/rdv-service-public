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
