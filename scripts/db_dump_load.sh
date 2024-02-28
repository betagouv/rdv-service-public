#!/bin/bash

set -ex

if (( $# == 0 )); then
  echo "Load Postgres dump into Rails develoment DB."
  echo "Usage: $0 <my_dump_file.pgsql>"; exit
fi

DUMP_NAME=$1

# create database
bundle exec rails db:drop db:create

# import dump
pg_restore --clean --if-exists --no-owner --no-privileges --dbname lapin_development "$DUMP_NAME" --jobs 4 -L <(pg_restore -l "$DUMP_NAME" | grep -vE 'TABLE DATA public (versions|good_jobs|good_job_settings|good_job_batches|good_job_processes)')

rm -f "$DUMP_NAME"

bundle exec rails db:environment:set

# Si vous avez besoin de débugger et que l'anonymisation complète vous bloque,
# vous devez au moins anonymiser les données usager avec:
# bundle exec rails runner 'Anonymizer.anonymize_user_data!'

bundle exec rails runner scripts/anonymize_database.rb
