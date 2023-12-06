#!/usr/bin/env bash
set -e
# Inspiré par https://doc.scalingo.com/platform/databases/duplicate

archive_name="backup.tar.gz"

# Install the Scalingo CLI tool in the container:
install-scalingo-cli

# Install additional tools to interact with the database:
dbclient-fetcher pgsql

# Login to Scalingo, using the token from the env variable
# This token has been set by an individuel member of the team.
scalingo login --api-token "${SCALINGO_API_TOKEN}"

# Retrieve the addon id:
addon_id="$( scalingo --region osc-secnum-fr1 --app production-rdv-solidarites addons \
             | grep "PostgreSQL" \
             | cut -d "|" -f 3 \
             | tr -d " " )"

# Download the latest backup available for the specified addon:
scalingo  --region osc-secnum-fr1 --app production-rdv-solidarites --addon "${addon_id}" backups-download --output "${archive_name}"

# Get the name of the backup file:
backup_file_name="$( tar --list --file="${archive_name}" \
                     | tail -n 1 \
                     | cut -d "/" -f 1 )"

# Extract the archive containing the downloaded backup:
tar --extract --verbose --file="${archive_name}" --directory="/app/"

# Delete the archive (not really necessary since the file system of the one-off container will be deleted anyways)
# rm backup.tar.gz

# TODO: block connections from the outside before loading the dump to the database
# this could be done by only authorizing the pg role used by metabase to access a pg schema other than public, and changing the schema name when the anonymization is done
# this could also be done by deleting and re-creating the pg role used by metabase around this operation

# Load the dump into the database
pg_restore --clean --if-exists --no-owner --no-privileges --dbname "${DATABASE_URL}" /app/*.pgsql


# Delete the dump (not really necessary since the file system of the one-off container will be deleted anyways)
# rm /app/*.pgsql

bundle exec rails runner scripts/anonymize_database.rb

