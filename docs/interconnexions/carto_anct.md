# Cartographie de déploiement de la suite terrritoriale (ANCT)

Afin de valoriser l'implantation des produits de l'incubateur,
l'ANCT met en place une cartographie. Afin que RDV Service Public
apparaisse sur cette carte, nous devons implémenter une API.

Elle doit répondre aux critères décrits dans cette spec :
https://docs.numerique.gouv.fr/docs/6b33b32e-2f58-4179-8d1b-7c01414c44d3/

## Comment mettre à jour les données

Cette première implémentation permet de répondre au besoin au plus vite :
on stocke les données dans le repo (~200 ko). Une implémentation avec
appel à Metabase pourra être envisagée, mais elle aurait pour inconvénient
de devoir faire des appels (longs et qui peuvent échouer) et / ou de gérer un cache.

Les 4 fichiers nécessaires à la production des metrics sont les 4 suivants :
- Nombre d'agents par code INSEE (RDV-Solidarités)
- Nombre d'agents par code INSEE (RDV-SP)
- Nombre d'agents par SIRET (RDV-Solidarités)
- Nombre d'agents par SIRET (RDV-SP)

Les 4 questions Metabase correspondantes sont stockées ici :
https://rdv-service-public-metabase.osc-secnum-fr1.scalingo.io/collection/74-carto-anct

Pour mettre à jour les fichiers du repo, il faut visiter les questions Metabase et
mettre à jour les 4 fichiers situés dans `lib/assets/carto_anct/`.

# Requêtes Metabase

Si les questions ne sont plus présentes sur Metabase, voici les requêtes SQL
utilisées pour compter les agents actifs (qui ont déjà fait un RDV).

Ces requêtes sont données pour la base de données RDV Service Public, pour obtenir
les données pour RDV-Solidarités, il suffit de remplacer `rdvsp` par `rdvs`.

## Nombre d'agent par code INSEE

```sql
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
```

## Nombre d'agent par SIRET

```sql
SELECT
  "rdvsp"."agents"."proconnect_siret" AS "siret",
  COUNT(DISTINCT "rdvsp"."agents"."id") AS tu
FROM
  "rdvsp"."agents"
JOIN
  "rdvsp"."agents_rdvs" ON "rdvsp"."agents_rdvs"."agent_id" = "rdvsp"."agents"."id"
JOIN
  "rdvsp"."rdvs" ON "rdvsp"."rdvs"."id" = "rdvsp"."agents_rdvs"."rdv_id"
GROUP BY
  "rdvsp"."agents"."proconnect_siret";
```
