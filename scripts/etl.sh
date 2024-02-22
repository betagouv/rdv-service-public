#!/usr/bin/env bash
set -e
# Inspiré par https://doc.scalingo.com/platform/databases/duplicate

if [ "$#" -lt 2 ]; then
    echo "Usage ./scripts/etl.sh <app> <env> <schema optionnel>"
    echo "<app> choisir parmis: rdvi, rdvsp"
    echo "<env> choisir parmis: demo, prod"
    echo "<schema> sera par défaut le nom de l'app, mais peut être surchargé ici"
    exit 1
fi

declare -A available_apps

available_apps["rdvi_demo"]="rdv-insertion-demo"
available_apps["rdvi_prod"]="rdv-insertion-prod"
available_apps["rdvsp_demo"]="demo-rdv-solidarites"
available_apps["rdvsp_prod"]="production-rdv-solidarites"

app=$1
env=$2
schema_name="${3:-$app}"
database=${available_apps["${app}_${env}"]}

read -p "Le process va maintenant importer <${app}> avec l'env <${env}> dans le schema <${schema_name}>, voulez-vous continuer ? (O/n): " answer

if [[ ! "$answer" =~ ^[Oo]$ ]]; then
  echo "Process annulé."
  exit 0
fi

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

echo "Upgrade du Postgres d'ETL pour avoir plus de RAM"
# On fait cette opération avant de télécharger le dump pour que le provisionnement du nouveau plan ai le temps de se finir avant le pg_restore
scalingo --region osc-secnum-fr1 --app rdv-service-public-etl addons-upgrade "${etl_addon_id}"  postgresql-starter-8192

# Retrieve the production addon id:
prod_addon_id="$( scalingo --region osc-secnum-fr1 --app "${database}" addons \
                 | grep "PostgreSQL" \
                 | cut -d "|" -f 3 \
                 | tr -d " " )"

# Download the latest backup available for the specified addon:
scalingo  --region osc-secnum-fr1 --app "${database}" --addon "${prod_addon_id}" backups-download --output "${archive_name}"

# Extract the archive containing the downloaded backup:
tar --extract --verbose --file="${archive_name}" --directory="/app/" 2>/dev/null

echo "Suppression du role postgres utilisé par metabase"
scalingo database-delete-user --region osc-secnum-fr1 --app rdv-service-public-etl --addon "${etl_addon_id}" rdv_service_public_metabase
echo "La base de données n'est plus accessible par metabase"

echo "Chargement du dump..."
pg_restore -O -x -f raw.sql *.pgsql
sed -i "s/public/${schema_name}/g" raw.sql

if [[ "$schema_name" != "public" ]]; then
  psql "${DATABASE_URL}" -c "DROP SCHEMA IF EXISTS \"${schema_name}\" CASCADE;"
  psql "${DATABASE_URL}" -c "CREATE SCHEMA \"${schema_name}\";"
else
  psql  -v ON_ERROR_STOP=0 "${DATABASE_URL}" < /app/scripts/clean_public_schema.sql
fi

psql  -v ON_ERROR_STOP=0 "${DATABASE_URL}" < /app/raw.sql

echo "Anonymisation de la base"
time bundle exec rails runner scripts/anonymize_database.rb "${app}" "${schema_name}"

echo "Re-création du role Postgres rdv_service_public_metabase"
echo "Merci de copier/coller le mot de passe stocké dans METABASE_DB_ROLE_PASSWORD: ${METABASE_DB_ROLE_PASSWORD}"
scalingo database-create-user --region osc-secnum-fr1 --app rdv-service-public-etl --addon "${etl_addon_id}" --read-only rdv_service_public_metabase

# On fait cette opération après la création du user, puisqu'elle cause un peu de downtime sur la db
echo "Downgrade du Postgres d'ETL pour revenir a la normale"
scalingo --region osc-secnum-fr1 --app rdv-service-public-etl addons-upgrade "${etl_addon_id}" postgresql-starter-512


