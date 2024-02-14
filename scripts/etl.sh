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

echo "Upgrade du Postgres d'ETL pour avoir plus de RAM"
# On fait cette opération avant de télécharger le dump pour que le provisionnement du nouveau plan ai le temps de se finir avant le pg_restore
scalingo --region osc-secnum-fr1 --app rdv-service-public-etl addons-upgrade "${etl_addon_id}"  postgresql-starter-8192

# Default to RDVS or use the first argument as the app name:
app_name="${1:-production-rdv-solidarites}"

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


etl_addon_id="$( scalingo --region osc-secnum-fr1 --app rdv-service-public-etl addons \
                 | grep "PostgreSQL" \
                 | cut -d "|" -f 3 \
                 | tr -d " " )"


echo "Chargement du dump..."
tables_to_exclude="$(bundle exec rails runner scripts/anonymizer_truncated_tables.rb ${app_name})"
time pg_restore --clean --if-exists --no-owner --no-privileges --jobs=4 --dbname "${DATABASE_URL}" -L <(pg_restore -l /app/*.pgsql | grep -vE "TABLE DATA public ($tables_to_exclude)") /app/*.pgsql

echo "Anonymisation de la base"
time bundle exec rails runner scripts/anonymize_database.rb "${app_name}"

echo "Renommage du schema vers '${app_name}'"
psql "${DATABASE_URL}" -c "ALTER SCHEMA public RENAME TO ${app_name};"

echo "Re-création du role Postgres rdv_service_public_metabase"
echo "Merci de copier/coller le mot de passe stocké dans METABASE_DB_ROLE_PASSWORD: ${METABASE_DB_ROLE_PASSWORD}"
scalingo database-create-user --region osc-secnum-fr1 --app rdv-service-public-etl --addon "${etl_addon_id}" --read-only rdv_service_public_metabase

# On fait cette opération après la création du user, puisqu'elle cause un peu de downtime sur la db
echo "Downgrade du Postgres d'ETL pour revenir a la normale"
scalingo --region osc-secnum-fr1 --app rdv-service-public-etl addons-upgrade "${etl_addon_id}" postgresql-starter-512


