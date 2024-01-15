#!/bin/bash

set -ex

if (( $# == 0 )); then
  echo "Load Postgres dump into Rails develoment DB."
  echo "Usage: $0 <my_dump_file.pgsql>"; exit
fi

DUMP_NAME=$1

# import
bundle exec rails db:drop db:create
pg_restore --clean --if-exists --no-owner --no-privileges --dbname lapin_development "$DUMP_NAME"

rm -f "$DUMP_NAME"

bundle exec rails db:environment:set

bundle exec rails runner scripts/anonymize_database.rb


