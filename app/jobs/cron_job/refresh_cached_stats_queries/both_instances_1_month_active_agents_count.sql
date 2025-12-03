SELECT
  SUM(subcount) AS c
FROM
  (
    SELECT
      COUNT(*) AS subcount
    FROM
      "rdvsp"."agents"
    WHERE
      (
        "rdvsp"."agents"."last_sign_in_at" >= CAST((NOW() + INTERVAL '-30 day') AS date)
      )
    UNION ALL
    SELECT
      COUNT(*) AS subcount
    FROM
      "rdvs"."agents"
    WHERE
      (
        "rdvs"."agents"."last_sign_in_at" >= CAST((NOW() + INTERVAL '-30 day') AS date)
      )
  );
