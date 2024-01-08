# Inspiré par https://doc.scalingo.com/platform/databases/duplicate

$stdout.sync = true

ETL_PG_ROLE_NAME = "rdv_service_public_metabase".freeze
ARCHIVE_NAME = "backup.tar.gz".freeze

require_relative "../app/lib/anonymizer_rules"
TRUNCATED_TABLES = AnonymizerRules::TRUNCATED_TABLES.join("|").freeze

def load_latest_dump_in_etl
  # Install the Scalingo CLI tool in the container:
  # puts_and_run "install-scalingo-cli"

  # Install additional tools to interact with the database:
  # puts_and_run "dbclient-fetcher pgsql"

  # Cette commande nécessite un login par un membre de l'équipe
  # On préfère faire un login à chaque rafraichissement des données plutôt que de laisser un token scalingo en variable d'env
  puts_and_run "scalingo login"

  # Retrieve the production Postgres addon id:
  prod_addon_id = postgres_addon_id(app_name: "production-rdv-solidarites")

  # Download the latest backup available for the specified addon:
  # puts_and_run %(scalingo  --region osc-secnum-fr1 --app production-rdv-solidarites --addon "#{prod_addon_id}" backups-download --output "#{ARCHIVE_NAME}")

  # Extract the archive containing the downloaded backup:
  # puts_and_run %(tar --extract --verbose --file="#{ARCHIVE_NAME}" --directory="/app/")

  # Retrieve the ETL Postgres addon id:
  etl_addon_id = postgres_addon_id(app_name: "rdv-service-public-etl")

  # Delete Postgres role (aka "role") name "rdv_service_public_metabase"
  puts_and_run %(scalingo database-delete-user --region osc-secnum-fr1 --app rdv-service-public-etl --addon #{etl_addon_id} #{ETL_PG_ROLE_NAME})

  # TODO: block connections from the outside before loading the dump to the database

  # Load the dump into the database
  # TODO: try speeding up the process by using the --jobs option

  # voir https://stackoverflow.com/questions/37038193/exclude-table-during-pg-restore pour l'explication des tables à exclure
  # puts_and_run(%(time pg_restore --clean --if-exists --no-owner --no-privileges --jobs=2 --dbname "#{ENV['DATABASE_URL']}" -L <(pg_restore -l /app/*.pgsql | grep -vE 'TABLE DATA public (#{TRUNCATED_TABLES})') /app/*.pgsql))

  # puts_and_run %(bundle exec rails runner scripts/anonymize_database.rb)

  # Add role to Postgres

  puts "Re-création du role Postgres #{ETL_PG_ROLE_NAME}..."
  puts "Merci de copier le mot de passe stocké dans METABASE_DB_ROLE_PASSWORD: #{ENV['METABASE_DB_ROLE_PASSWORD']}"
  puts_and_run %(scalingo database-create-user --region osc-secnum-fr1 --app rdv-service-public-etl --addon #{etl_addon_id} --read-only #{ETL_PG_ROLE_NAME})
end

def puts_and_run(command)
  puts "> #{command}"
  `#{command}`
end

def postgres_addon_id(app_name:)
  `scalingo --region osc-secnum-fr1 --app #{app_name} addons`
    .each_line
    .find { _1 =~ /PostgreSQL/ }
    .split("|")[2]
    .strip
end

load_latest_dump_in_etl
