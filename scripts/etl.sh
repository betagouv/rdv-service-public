#!/usr/bin/env bash
# Exemple d'usage : scalingo --app=rdv-service-public-etl --region=osc-secnum-fr1 run ./scripts/etl.sh rdvsp prod public
# Exemple d'usage : scalingo --app=rdv-service-public-etl --region=osc-secnum-fr1 run ./scripts/etl.sh rdvsp_mairie prod rdv_anct_gouv_fr
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
available_apps["rdvsp_mairie_prod"]="production-rdv-mairie"

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

if [[ "$schema_name" != "public" ]]; then

  pg_restore --no-owner --no-privileges --file=raw.sql *.pgsql
  sed -i "s/ public/ ${schema_name}/g" raw.sql
  psql "${DATABASE_URL}" -c "DROP SCHEMA IF EXISTS \"${schema_name}\" CASCADE;"
  psql "${DATABASE_URL}" -c "CREATE SCHEMA \"${schema_name}\";"

  psql  -v ON_ERROR_STOP=0 "${DATABASE_URL}" < /app/raw.sql
else
  time pg_restore --clean --if-exists --no-owner --no-privileges --jobs=4 --dbname "${DATABASE_URL}" -L <(pg_restore -l /app/*.pgsql | grep -vE 'TABLE DATA public (versions|good_jobs|good_job_settings|good_job_batches|good_job_processes)') /app/*.pgsql

fi


echo "Anonymisation de la base"
time bundle exec rails runner scripts/anonymize_database.rb "${app}" "${schema_name}"

psql "${DATABASE_URL}" -c "GRANT USAGE ON SCHEMA ${schema_name} TO rdv_service_public_metabase;"
psql "${DATABASE_URL}" -c "GRANT SELECT ON ALL TABLES IN SCHEMA ${schema_name} TO rdv_service_public_metabase;"

echo "Re-création du role Postgres rdv_service_public_metabase"
echo "Merci de copier/coller le mot de passe stocké dans METABASE_DB_ROLE_PASSWORD: ${METABASE_DB_ROLE_PASSWORD}"
scalingo database-create-user --region osc-secnum-fr1 --app rdv-service-public-etl --addon "${etl_addon_id}" --read-only rdv_service_public_metabase
