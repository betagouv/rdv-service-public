# Inspiré par https://doc.scalingo.com/platform/databases/duplicate

# Install the Scalingo CLI tool in the container:
puts `install-scalingo-cli`

# Install additional tools to interact with the database:
puts `dbclient-fetcher pgsql`

# Cette commande nécessite un login par un membre de l'équipe
# On préfère faire un login à chaque rafraichissement des données plutôt que de laisser un token scalingo en variable d'env
puts `scalingo login`

# Retrieve the addon id:
addon_in = `scalingo --region osc-secnum-fr1 --app production-rdv-solidarites addons`
  .each_line
  .find { _1 =~ /PostgreSQL/ }
  .split("|")[2]
  .strip

# Download the latest backup available for the specified addon:
archive_name = "backup.tar.gz"
puts `scalingo  --region osc-secnum-fr1 --app production-rdv-solidarites --addon "#{addon_in}" backups-download --output "#{archive_name}"`

# Extract the archive containing the downloaded backup:
puts `tar --extract --verbose --file="#{archive_name}" --directory="/app/"`

# TODO: block connections from the outside before loading the dump to the database
# The postgres role used by the rails app doesn't have the necessary permissions to create a new role
# this could be done by only authorizing the pg role used by metabase to access a pg schema other than public, and changing the schema name when the anonymization is done
# this could also be done by deleting and re-creating the pg role used by metabase around this operation

# cette commande échoue puisqu'on n'a pas les permissions nécessaires pour créer le rôle.
# Pour le moment, il faut encore supprimer et recréer le rôle via l'interface scalingo
puts "DROP ROLE rdv_service_public_metabase;\n"
`bundle exec rails dbconsole`

# Load the dump into the database
# TODO: try speeding up the process by using the --jobs option

# voir https://stackoverflow.com/questions/37038193/exclude-table-during-pg-restore pour l'explication des tables à exclure
# TODO: réutiliser AnonymizerRules::TRUNCATED_TABLES ici
# C'est compliqué à écrire en bash, et il vaudrait mieux utiliser du ruby pour ce genre de logique
# tables_to_exclude="$(bundle exec rails runner \"puts AnonymizerRules::TRUNCATED_TABLES.join\(\'\|\'\)\") | tail -n1"
`time pg_restore --clean --if-exists --no-owner --no-privileges --jobs=2 --dbname "#{ENV["DATABASE_URL"]}" \
  -L <(pg_restore -l /app/*.pgsql | grep -vE 'TABLE DATA public (versions|good_jobs|good_job_settings|good_job_batches|good_job_processes)') /app/*.pgsql`

puts `bundle exec rails runner scripts/anonymize_database.rb`

# Il faut qu'on trouve une manière d'automatiser la création de role
puts "CREATE ROLE rdv_service_public_metabase PASSWORD '${METABASE_DB_ROLE_PASSWORD}';\n"
`bundle exec rails dbconsole`
