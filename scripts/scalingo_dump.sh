#!/bin/bash

set -ex

if (( $# == 0 )); then
  echo "Dump the latest backup from scalingo and restore it in the local development DB."
  echo "Usage: $0 <demo or production>"; exit
fi

# download
REGION=osc-secnum-fr1
APP="$1"-rdv-solidarites
ADDON_ID=$(scalingo addons --region $REGION --app "$APP" | grep PostgreSQL | cut -d ' ' -f 4)

# download archive file
scalingo backups-download --region $REGION --app "$APP" --addon "$ADDON_ID"
# get name of most recently created tar.gz file (most likely the archive)
TAR_NAME=$(ls -t | grep tar.gz | head -n1)

# untar
tar xf "$TAR_NAME"
DUMP_NAME=$(basename "$TAR_NAME" .tar.gz).pgsql

# import
bundle exec rails db:drop db:create
pg_restore --clean --if-exists --no-owner --no-privileges --no-comments --dbname lapin_development "$DUMP_NAME"
bundle exec rails db:environment:set

rm -f "$TAR_NAME" "$DUMP_NAME"
