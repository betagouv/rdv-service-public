# on your laptop
# add rdv-solidarites-metabase to your /etc/hosts

# in terminal 1
scalingo -a production-rdv-solidarites db-tunnel SCALINGO_POSTGRESQL_URL
# (maybe enter SSH password)

# in terminal 2

pg_dump --clean --no-owner --no-privileges --exclude-schema 'information_schema' --exclude-schema '^pg_*' --file rdv_solidarites.prod_dump.sql postgresql://XXXXX:XXXXX@127.0.0.1:10000/XXXX
# (maybe re-enter SSH password in terminal 1)

scp rdv_solidarites.prod_dump.sql root@rdv-solidarites-metabase-1:/home/app/pgdata/dumps
ssh root@rdv-solidarites-metabase

# on scaleway instance

cd /home/app
docker stop app_metabase-app_1
docker exec -it --user=postgres app_postgres-db_1 dropdb rdv_solidarites
docker exec -it --user=postgres app_postgres-db_1 createdb rdv_solidarites
cat /home/app/pgdata/dumps/rdv_solidarites.prod_dump.sql | docker exec -i --user=postgres app_postgres-db_1 psql rdv_solidarites
docker-compose up -d
