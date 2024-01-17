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

# Retrieve the production addon id:
prod_addon_id="$( scalingo --region osc-secnum-fr1 --app production-rdv-solidarites addons \
                 | grep "PostgreSQL" \
                 | cut -d "|" -f 3 \
                 | tr -d " " )"

# Download the latest backup available for the specified addon:
scalingo  --region osc-secnum-fr1 --app production-rdv-solidarites --addon "${prod_addon_id}" backups-download --output "${archive_name}"

# Extract the archive containing the downloaded backup:
tar --extract --verbose --file="${archive_name}" --directory="/app/"

# TODO: block connections from the outside before loading the dump to the database

etl_addon_id="$( scalingo --region osc-secnum-fr1 --app rdv-service-public-etl addons \
                 | grep "PostgreSQL" \
                 | cut -d "|" -f 3 \
                 | tr -d " " )"

echo "Suppression du role postgres."
# Delete Postgres role dedicated to metabase and called "rdv_service_public_metabase"
scalingo database-delete-user --region osc-secnum-fr1 --app rdv-service-public-etl --addon "${etl_addon_id}" rdv_service_public_metabase
echo "La base de données n'est plus accessible par metabase"


echo "Upgrade du Postgres d'ETL pour avoir plus de RAM"
scalingo --region osc-secnum-fr1 --app rdv-service-public-etl addons-upgrade "${etl_addon_id}"  postgresql-starter-8192

echo "Chargement du dump..."
# TODO: try speeding up the process by using the --jobs option
# voir https://stackoverflow.com/questions/37038193/exclude-table-during-pg-restore pour l'explication des tables à exclure
# TODO: réutiliser AnonymizerRules::TRUNCATED_TABLES ici
# C'est compliqué à écrire en bash, et il vaudrait mieux utiliser du ruby pour ce genre de logique
# tables_to_exclude="$(bundle exec rails runner \"puts AnonymizerRules::TRUNCATED_TABLES.join\(\'\|\'\)\") | tail -n1"
time pg_restore --clean --if-exists --no-owner --no-privileges --jobs=2 --dbname "${DATABASE_URL}" -L <(pg_restore -l /app/*.pgsql | grep -vE 'TABLE DATA public (versions|good_jobs|good_job_settings|good_job_batches|good_job_processes)') /app/*.pgsql


echo "Anonymisation de la base"
time bundle exec rails runner scripts/anonymize_database.rb

echo "Downgrade du Postgres d'ETL pour revenir a la normale"
scalingo --region osc-secnum-fr1 --app rdv-service-public-etl addons-upgrade "${etl_addon_id}" postgresql-starter-512

echo "Re-création du role Postgres rdv_service_public_metabase"
echo "Merci de copier/coller le mot de passe stocké dans METABASE_DB_ROLE_PASSWORD: ${METABASE_DB_ROLE_PASSWORD}"
scalingo database-create-user --region osc-secnum-fr1 --app rdv-service-public-etl --addon "${etl_addon_id}" --read-only rdv_service_public_metabase
