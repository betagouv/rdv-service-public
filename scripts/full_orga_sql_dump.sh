#!/bin/sh

# ./scripts/full_orga_sql_dump.sh 83 postgresql://localhost/rdv-sol-prod-dump
# ./scripts/full_orga_sql_dump.sh ORGANISATION_ID $DATABASE_URL

set -e  # will exit upon failure

ORGANISATION_ID=$1
SOURCE_DB_URL=$2

DUMP_ID=$ORGANISATION_ID-`date +"%Y_%m_%d_%HH%M"`
OUTPUT_PATH=$(pwd)/tmp/dump_organisation_$DUMP_ID
TEMP_DB_NAME=rdv-solidarites-dump-$DUMP_ID
TEMP_DB_URL=postgresql://localhost/$TEMP_DB_NAME

mkdir -p $OUTPUT_PATH

echo "exporting db schema..."
pg_dump --schema-only --file $OUTPUT_PATH/schema.pg_dump $SOURCE_DB_URL

echo "exporting all data from organisation $ORGANISATION_ID from DB to CSV files..."

# common data
psql $SOURCE_DB_URL -c "COPY services TO '$OUTPUT_PATH/services.csv' CSV HEADER;"

# direct links
psql $SOURCE_DB_URL -c "COPY (SELECT * FROM organisations WHERE id=$ORGANISATION_ID) TO '$OUTPUT_PATH/organisations.csv' CSV HEADER;"
psql $SOURCE_DB_URL -c "COPY (SELECT * FROM absences              WHERE organisation_id=$ORGANISATION_ID) TO '$OUTPUT_PATH/absences.csv' CSV HEADER;"
psql $SOURCE_DB_URL -c "COPY (SELECT * FROM agent_roles  WHERE organisation_id=$ORGANISATION_ID) TO '$OUTPUT_PATH/agent_roles.csv' CSV HEADER;"
psql $SOURCE_DB_URL -c "COPY (SELECT * FROM lieux                 WHERE organisation_id=$ORGANISATION_ID) TO '$OUTPUT_PATH/lieux.csv' CSV HEADER;"
psql $SOURCE_DB_URL -c "COPY (SELECT * FROM motifs                WHERE organisation_id=$ORGANISATION_ID) TO '$OUTPUT_PATH/motifs.csv' CSV HEADER;"
psql $SOURCE_DB_URL -c "COPY (SELECT * FROM plage_ouvertures      WHERE organisation_id=$ORGANISATION_ID) TO '$OUTPUT_PATH/plage_ouvertures.csv' CSV HEADER;"
# psql $SOURCE_DB_URL -c "COPY (SELECT * FROM rdvs                  WHERE organisation_id=$ORGANISATION_ID) TO '$OUTPUT_PATH/rdvs.csv' CSV HEADER;"
psql $SOURCE_DB_URL -c "COPY (SELECT * FROM user_profiles         WHERE organisation_id=$ORGANISATION_ID) TO '$OUTPUT_PATH/user_profiles.csv' CSV HEADER;"
psql $SOURCE_DB_URL -c "COPY (SELECT * FROM zones                 WHERE organisation_id=$ORGANISATION_ID) TO '$OUTPUT_PATH/zones.csv' CSV HEADER;"

# special case for RDVS because of https://metabase-rdv-solidarites.osc-fr1.scalingo.io/question/6

psql $SOURCE_DB_URL -c "COPY (
  SELECT rdvs.* FROM rdvs
  LEFT JOIN lieux ON lieux.id = rdvs.lieu_id
  WHERE rdvs.organisation_id=$ORGANISATION_ID AND lieux.organisation_id=$ORGANISATION_ID
) TO '$OUTPUT_PATH/rdvs.csv' CSV HEADER;"

# joined links

psql $SOURCE_DB_URL -c "COPY (
  SELECT agents.* FROM agents
  LEFT JOIN agent_roles ON agent_roles.agent_id = agents.id
  WHERE agent_roles.organisation_id=$ORGANISATION_ID
) TO '$OUTPUT_PATH/agents.csv' CSV HEADER;"
psql $SOURCE_DB_URL -c "COPY (
  SELECT agents_rdvs.* FROM agents_rdvs
  LEFT JOIN agent_roles ON agent_roles.agent_id = agents_rdvs.agent_id
  WHERE agent_roles.organisation_id=$ORGANISATION_ID
) TO '$OUTPUT_PATH/agents_rdvs.csv' CSV HEADER;"
psql $SOURCE_DB_URL -c "COPY (
  SELECT agents_users.* FROM agents_users
  LEFT JOIN agent_roles ON agent_roles.agent_id = agents_users.agent_id
  WHERE agent_roles.organisation_id=$ORGANISATION_ID
) TO '$OUTPUT_PATH/agents_users.csv' CSV HEADER;"
psql $SOURCE_DB_URL -c "COPY (
  SELECT file_attentes.* FROM file_attentes
  LEFT JOIN rdvs ON rdvs.id = file_attentes.rdv_id
  WHERE rdvs.organisation_id=$ORGANISATION_ID
) TO '$OUTPUT_PATH/file_attentes.csv' CSV HEADER;"
psql $SOURCE_DB_URL -c "COPY (
  SELECT motifs_plage_ouvertures.* FROM motifs_plage_ouvertures
  LEFT JOIN motifs ON motifs.id = motifs_plage_ouvertures.motif_id
  WHERE motifs.organisation_id=$ORGANISATION_ID
) TO '$OUTPUT_PATH/motifs_plage_ouvertures.csv' CSV HEADER;"
psql $SOURCE_DB_URL -c "COPY (
  SELECT rdv_events.* FROM rdv_events
  LEFT JOIN rdvs ON rdvs.id = rdv_events.rdv_id
  WHERE rdvs.organisation_id=$ORGANISATION_ID
) TO '$OUTPUT_PATH/rdv_events.csv' CSV HEADER;"
psql $SOURCE_DB_URL -c "COPY (
  SELECT rdvs_users.* FROM rdvs_users
  LEFT JOIN rdvs ON rdvs.id = rdvs_users.rdv_id
  WHERE rdvs.organisation_id=$ORGANISATION_ID
) TO '$OUTPUT_PATH/rdvs_users.csv' CSV HEADER;"
psql $SOURCE_DB_URL -c "COPY (
  SELECT * FROM users WHERE id IN (
    (
      SELECT users.responsible_id FROM users
      LEFT JOIN user_profiles ON user_profiles.user_id = users.id
      WHERE user_profiles.organisation_id=$ORGANISATION_ID
    )
    UNION ALL (
      SELECT users.id FROM users
      LEFT JOIN user_profiles ON user_profiles.user_id = users.id
      WHERE user_profiles.organisation_id=$ORGANISATION_ID
    )
  ) ORDER BY responsible_id
) TO '$OUTPUT_PATH/users.csv' CSV HEADER;"

# version
echo "creating temporary PostgreSQL database $TEMP_DB_NAME..."
createdb $TEMP_DB_NAME

echo "loading schema..."
cat $OUTPUT_PATH/schema.pg_dump | psql $TEMP_DB_URL

echo "importing data into tmp db..."
# note that the order is important to respect FKs
psql $TEMP_DB_URL -c "COPY services FROM '$OUTPUT_PATH/services.csv' CSV HEADER;"
psql $TEMP_DB_URL -c "COPY organisations FROM '$OUTPUT_PATH/organisations.csv' CSV HEADER;"
psql $TEMP_DB_URL -c "COPY agents FROM '$OUTPUT_PATH/agents.csv' CSV HEADER;"
psql $TEMP_DB_URL -c "COPY absences FROM '$OUTPUT_PATH/absences.csv' CSV HEADER;"
psql $TEMP_DB_URL -c "COPY agent_roles FROM '$OUTPUT_PATH/agent_roles.csv' CSV HEADER;"
psql $TEMP_DB_URL -c "COPY lieux FROM '$OUTPUT_PATH/lieux.csv' CSV HEADER;"
psql $TEMP_DB_URL -c "COPY motifs FROM '$OUTPUT_PATH/motifs.csv' CSV HEADER;"
psql $TEMP_DB_URL -c "COPY plage_ouvertures FROM '$OUTPUT_PATH/plage_ouvertures.csv' CSV HEADER;"
psql $TEMP_DB_URL -c "COPY rdvs FROM '$OUTPUT_PATH/rdvs.csv' CSV HEADER;"
psql $TEMP_DB_URL -c "COPY user_profiles FROM '$OUTPUT_PATH/user_profiles.csv' CSV HEADER;"
psql $TEMP_DB_URL -c "COPY zones FROM '$OUTPUT_PATH/zones.csv' CSV HEADER;"
psql $TEMP_DB_URL -c "COPY agents_rdvs FROM '$OUTPUT_PATH/agents_rdvs.csv' CSV HEADER;"
psql $TEMP_DB_URL -c "COPY agents_users FROM '$OUTPUT_PATH/agents_users.csv' CSV HEADER;"
psql $TEMP_DB_URL -c "COPY motifs_plage_ouvertures FROM '$OUTPUT_PATH/motifs_plage_ouvertures.csv' CSV HEADER;"
psql $TEMP_DB_URL -c "COPY rdv_events FROM '$OUTPUT_PATH/rdv_events.csv' CSV HEADER;"
psql $TEMP_DB_URL -c "COPY rdvs_users FROM '$OUTPUT_PATH/rdvs_users.csv' CSV HEADER;"
psql $TEMP_DB_URL -c "COPY users FROM '$OUTPUT_PATH/users.csv' CSV HEADER;"
psql $TEMP_DB_URL -c "COPY file_attentes FROM '$OUTPUT_PATH/file_attentes.csv' CSV HEADER;"

echo "exporting SQL dump"
pg_dump --clean --no-owner --no-privileges --file $OUTPUT_PATH/full_dump_organisation_$ORGANISATION_ID.sql $TEMP_DB_NAME

echo "dropping temporary db..."
dropdb $TEMP_DB_NAME

echo "Done, all files are in $OUTPUT_PATH"
