#!/bin/bash

set -ex

DEFAULT_EXCEPT_TABLES="versions,good_jobs,good_job_executions,good_job_settings,good_job_batches,good_job_processes"
USER_DATA_TABLES="receipts,users,participations,user_profiles,referent_assignations,annotations,file_attentes"

if (( $# == 0 )); then
  echo "Load Postgres dump into Rails develoment DB."
  echo "Usage:"
  echo "$0 <my_dump_file.pgsql> [options]"
  echo "Options (table lists are comma-separated):"
  echo "  --only-tables=a,b    restore the data of these tables only"
  echo "  --except-tables=a,b  restore the data of all tables except these (default: $DEFAULT_EXCEPT_TABLES)"
  echo "  --ignore-user-data   also skip the tables containing user data ($USER_DATA_TABLES)"
  echo "The schema is always fully restored."
  exit
fi

DUMP_NAME=$1
shift

# Parse options
ONLY_TABLES=""
EXCEPT_TABLES="$DEFAULT_EXCEPT_TABLES"
for arg in "$@"; do
  case "$arg" in
    --only-tables=*)   ONLY_TABLES="${arg#--only-tables=}" ;;
    --except-tables=*) EXCEPT_TABLES="${arg#--except-tables=}" ;;
    --ignore-user-data) EXCEPT_TABLES="$EXCEPT_TABLES,$USER_DATA_TABLES" ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

# Build a regex that matches the "TABLE DATA" lines we do NOT want to restore.
if [ -n "$ONLY_TABLES" ]; then
  # Skip the data of every table that is not in the list ("(?!...)" means "not followed by")
  SKIPPED_DATA_REGEX="TABLE DATA public (?!(${ONLY_TABLES//,/|})( |\$))"
else
  SKIPPED_DATA_REGEX="TABLE DATA public (${EXCEPT_TABLES//,/|})( |\$)"
fi

# create database
bundle exec rails db:drop db:create

pg_restore --clean --if-exists --no-owner --no-privileges --dbname rdv_service_public_dev "$DUMP_NAME" --jobs 4 -L <(pg_restore -l "$DUMP_NAME" | grep -vP "$SKIPPED_DATA_REGEX")

rm -f "$DUMP_NAME"

bundle exec rails db:environment:set

# Si vous avez besoin de débugger et que l'anonymisation complète vous bloque,
# vous devez au moins anonymiser les données usager avec :
# bundle exec rails runner scripts/devtools/anonymize_user_data.rb

#bundle exec rails runner scripts/devtools/anonymize_database.rb
