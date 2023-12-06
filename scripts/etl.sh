#!/usr/bin/env bash

archive_name="backup.tar.gz"

# Install the Scalingo CLI tool in the container:
install-scalingo-cli

# Install additional tools to interact with the database:
dbclient-fetcher PostgreSQL

# Login to Scalingo, using the token from the env variable
# This token has been set by an individuel member of the team.
scalingo login --api-token "${SCALINGO_API_TOKEN}"

# Retrieve the addon id:
addon_id="$( scalingo --region osc-secnum-fr1 --app -rdv-solidarites addons \
             | grep "PostgreSQL" \
             | cut -d "|" -f 3 \
             | tr -d " " )"

# Download the latest backup available for the specified addon:
scalingo --app demo-rdv-solidarites --addon "PostgreSQL" backups-download --output "${archive_name}"

# Get the name of the backup file:
backup_file_name="$( tar --list --file="${archive_name}" \
                     | tail -n 1 \
                     | cut -d "/" -f 1 )"

# Extract the archive containing the downloaded backup:
tar --extract --verbose --file="${archive_name}" --directory="/app/"

pg_restore --clean --if-exists --no-owner --no-privileges --dbname "${DATABASE_URL}" "/app/${backup_file_name}"

bundle exec rails runner scripts/anonymize_database.rb
