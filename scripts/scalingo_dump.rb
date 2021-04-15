# ruby scripts/scalingo_dump.rb

require "optparse"
require "json"
require "typhoeus"
require "dotenv/load"
require "open-uri"

HEADERS = {
  "Accept" => "application/json",
  "Content-Type" => "application/json"
}.freeze

options = {}
OptionParser.new do |parser|
  parser.on("-e", "--env ENV_NAME", "Environment (demo or production)") do |val|
    raise StandardError, "invalid ENV_NAME option, must be 'demo' or 'production" \
      unless %w[demo production].include?(val)

    options[:app_name] = "#{val}-rdv-solidarites"
  end
end.parse!
raise StandardError, "missing --env ENV_NAME option" if options[:app_name].nil?

raise StandardError, "missing SCALINGO_API_TOKEN environment variable, cf https://my.osc-secnum-fr1.scalingo.com/profile" \
  if ENV["SCALINGO_API_TOKEN"].nil?

bearer_token = JSON.parse(
  Typhoeus.post(
    "https://auth.scalingo.com/v1/tokens/exchange",
    headers: HEADERS,
    userpwd: ":#{ENV['SCALINGO_API_TOKEN']}"
  ).body
)["token"]

addons = JSON.parse(
  Typhoeus.get(
    "https://api.osc-secnum-fr1.scalingo.com/v1/apps/#{options[:app_name]}/addons",
    headers: HEADERS.merge({ "Authorization" => "Bearer #{bearer_token}" })
  ).body
)["addons"]
addon_db = addons.first { _1["name"] == "PostgreSQL" }
puts addon_db

bearer_token_db = JSON.parse(
  Typhoeus.post(
    "https://api.osc-secnum-fr1.scalingo.com/v1/apps/#{options[:app_name]}/addons/#{addon_db['id']}/token",
    headers: HEADERS.merge({ "Authorization" => "Bearer #{bearer_token}" })
  ).body
)["addon"]["token"]
puts bearer_token_db

backups = JSON.parse(
  Typhoeus.get(
    "https://db-api.osc-secnum-fr1.scalingo.com/api/databases/#{addon_db['id']}/backups",
    headers: HEADERS.merge({ "Authorization" => "Bearer #{bearer_token_db}" })
  ).body
)["database_backups"]
backup_most_recent = backups.max_by { _1["created_at"] }

backup_dl_url = JSON.parse(
  Typhoeus.get(
    "https://db-api.osc-secnum-fr1.scalingo.com/api/databases/#{addon_db['id']}/backups/#{backup_most_recent['id']}/archive",
    headers: HEADERS.merge({ "Authorization" => "Bearer #{bearer_token_db}" })
  ).body
)["download_url"]
puts backup_dl_url

puts "downloading #{(backup_most_recent['size'] / 1024 / 1024).round}MB backup from #{backup_most_recent['created_at']}..."
backup_tar_path = "./prod-dump.tar.gz"
File.open(backup_tar_path, "wb") do |file|
  file.write(URI.parse(backup_dl_url).open.read)
end
puts "done downloading to {backup_tar_path}, now untar ..."

`tar -xvzf #{backup_tar_path}`
puts "untar done!"
`rm #{backup_tar_path}`

backup_pgsql_filename = Dir.entries(".").select { _1 =~ /\.pgsql$/ }.first
backup_pgsql_path = "./#{backup_pgsql_filename}"

`dropdb #{options[:app_name]}-dump --if-exists`
`createdb #{options[:app_name]}-dump`
`pg_restore -d #{options[:app_name]}-dump #{backup_pgsql_path}`
`rm #{backup_pgsql_path}`

`sed -i.backup 's/lapin_development/#{options[:app_name]}-dump/' config/database.yml`
