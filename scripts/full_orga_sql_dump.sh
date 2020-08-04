#!/bin/sh

# ./scripts/full_orga_sql_dump.sh 1

ORGANISATION_ID=$1
DUMP_ID=$RANDOM
OUTPUT_PATH=tmp/dump_$DUMP_ID
DB_NAME=rdv-solidarites-dump-$DUMP_ID
DB_URL=postgresql://localhost/$DB_NAME

spring stop

echo "exporting orga $ORGANISATION_ID from DB..."
bundle exec rails runner scripts/export_organisation.rb $DUMP_ID $ORGANISATION_ID

echo "preparing tmp postgresql db..."
createdb $DB_NAME

echo "stopping spring..."
spring stop

echo "loading schema..."
DATABASE_URL=$DB_URL rails db:schema:load

echo "importing data into tmp db..."
DATABASE_URL=$DB_URL bundle exec rails runner scripts/import_organisation.rb $DUMP_ID

echo "exporting SQL dump"
pg_dump --clean --no-owner --no-privileges --file $OUTPUT_PATH/full_dump_organisation_$ORGANISATION_ID.sql $DB_URL

echo "dropping temporary db..."
dropdb $DB_NAME

echo "Done, all files are in $OUTPUT_PATH"

spring stop
