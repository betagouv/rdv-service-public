# Usage : scalingo --app=rdv-service-public-etl --region=osc-secnum-fr1 run "bash"
# puis ./scripts/etl.sh demo-rdv-solidarites
#
#!/usr/bin/env bash
set -e
# Inspiré par https://doc.scalingo.com/platform/databases/duplicate

archive_name="backup.tar.gz"

# Install the Scalingo CLI tool in the container:
install-scalingo-cli

# Install additional tools to interact with the database:
dbclient-fetcher pgsql

# Cette commande nécessite un login par un membre de l'équipe
# On préfère faire un login à chaque rafraichissement des données plutôt que de laisser un token scalingo en variable d'env
scalingo login --password-only

etl_addon_id="$( scalingo --region osc-secnum-fr1 --app rdv-service-public-etl addons \
  | grep "PostgreSQL" \
  | cut -d "|" -f 3 \
  | tr -d " " )"

app_name="${1:-production-rdv-solidarites}"

echo "Upgrade du Postgres d'ETL pour avoir plus de RAM"
# On fait cette opération avant de télécharger le dump pour que le provisionnement du nouveau plan ai le temps de se finir avant le pg_restore
scalingo --region osc-secnum-fr1 --app rdv-service-public-etl addons-upgrade "${etl_addon_id}"  postgresql-starter-8192

# Retrieve the production addon id:
prod_addon_id="$( scalingo --region osc-secnum-fr1 --app "${app_name}" addons \
                 | grep "PostgreSQL" \
                 | cut -d "|" -f 3 \
                 | tr -d " " )"

# Download the latest backup available for the specified addon:
scalingo  --region osc-secnum-fr1 --app "${app_name}" --addon "${prod_addon_id}" backups-download --output "${archive_name}"

# Extract the archive containing the downloaded backup:
tar --extract --verbose --file="${archive_name}" --directory="/app/"

echo "Suppression du role postgres utilisé par metabase"
scalingo database-delete-user --region osc-secnum-fr1 --app rdv-service-public-etl --addon "${etl_addon_id}" rdv_service_public_metabase
echo "La base de données n'est plus accessible par metabase"

# On fait un tail -n1 pour enlever des logs écrits par des gems (dont Skylight) pour garder uniquement les noms de tables
tables_to_exclude="$(bundle exec rails runner scripts/anonymizer_truncated_tables.rb | tail -n1)"

echo "Chargement du dump..."
# voir https://stackoverflow.com/questions/37038193/exclude-table-during-pg-restore pour l'explication des tables à exclure
time pg_restore --clean --if-exists --no-owner --no-privileges --jobs=4 --dbname "${DATABASE_URL}" -L <(pg_restore -l /app/*.pgsql | grep -vE "TABLE DATA public (${tables_to_exclude})") /app/*.pgsql


echo "Anonymisation de la base"
time bundle exec rails runner scripts/anonymize_database.rb

echo "Suppression de l'ancien schema '${app_name}'"
psql "${DATABASE_URL}" -c "DROP SCHEMA IF EXISTS \"${app_name}\" CASCADE;"

echo "Renommage du nouveau schema vers '${app_name}'"
psql "${DATABASE_URL}" -c "CREATE SCHEMA \"${app_name}\";"

all_tables=$(psql "${DATABASE_URL}" -t -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';")

# On bouge les tables vers le nouveau schema
for table in ${all_tables}; do
  psql "${DATABASE_URL}" -c "ALTER TABLE ${table} SET SCHEMA \"${app_name}\";"
done

echo "Re-création du role Postgres rdv_service_public_metabase"
echo "Merci de copier/coller le mot de passe stocké dans METABASE_DB_ROLE_PASSWORD: ${METABASE_DB_ROLE_PASSWORD}"
scalingo database-create-user --region osc-secnum-fr1 --app rdv-service-public-etl --addon "${etl_addon_id}" --read-only rdv_service_public_metabase

# On fait cette opération après la création du user, puisqu'elle cause un peu de downtime sur la db
echo "Downgrade du Postgres d'ETL pour revenir a la normale"
scalingo --region osc-secnum-fr1 --app rdv-service-public-etl addons-upgrade "${etl_addon_id}" postgresql-starter-512

