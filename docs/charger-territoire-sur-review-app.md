# Comment charger les données anonymisées d'un territoire sur une review app

# 1. Préparer les données en local

Télécharger un dump de prod depuis Scalingo, puis le charger en local : 

```bash
 ./scripts/db_dump_load.sh nom_du_dump.pgsql
```

Supprimer les données de tous les territoires sauf un +  anonymiser les données à l'aide du script `tronquer_et_anonymiser_db.rb` (peut prendre quelques minutes) :

```bash
bundle exec rails runner scripts/tronquer_et_anonymiser_db.rb ID_TERRITOIRE
```

## 2. Copier la base locale sur la review app

*Note : toutes les instructions listées ici ont été tirées de la doc Scalingo ["How to dump and restore my Scalingo for PostgreSQL®"](https://doc.scalingo.com/databases/postgresql/dump-restore).*

Il faut d'abord supprimer les données existantes sur la review app. Pour ce faire, lancer une console

```bash
REVIEW_APP_NAME=demo-rdv-solidarites-prXXXX
scalingo --app $REVIEW_APP_NAME --region osc-secnum-fr1 pgsql-console
```

puis supprimer les tables du schema public :

```sql
DO $$ 
DECLARE 
   tabname RECORD; 
BEGIN 
   FOR tabname IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') 
   LOOP 
      EXECUTE 'DROP TABLE IF EXISTS ' || tabname.tablename || ' CASCADE'; 
   END LOOP; 
END $$;
```

Nous allons maintenant dumper les données locales :

```bash
LOCAL_DATABASE_URL=postgresql://postgres:mot_de_passe_local@localhost/lapin_development
pg_dump --clean --if-exists --format c --dbname $LOCAL_DATABASE_URL --no-owner --no-privileges --no-comments --exclude-schema 'information_schema' --exclude-schema '^pg_*' --file tmp/dump.pgsql
```

Afin de charger ce dump sur la review app, il faut rendre la DB de la review app accessible depuis internet. Pour ce faire :

- visiter le dashboard de la review app
- dans la section "Resources", cliquer sur "Go to dashboard" face à l'addon-on Postgres
- activer l'option "Force connections using TLS"
- activer l'option "Internet Accessibility"

Nous allons alors pouvoir restaurer la base locale vers la DB distante en fournissant à `pg_restore` l'URL présente dans la variable d'environnement `SCALINGO_POSTGRESQL_URL` **de la review app**.

```bash
REVIEW_APP_DB_URL=url_trouvee_dans_les_variables_denv_de_la_review_app
pg_restore --clean --if-exists --no-owner --no-privileges --no-comments --dbname $REVIEW_APP_DB_URL tmp/dump.pgsql
```

La base locale est désormais copiée sur la review app !

N'oubliez pas de supprimer votre dump :

```bash
rm tmp/dump.pgsql
```
