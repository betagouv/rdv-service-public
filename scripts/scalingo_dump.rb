# rails runner scripts/scalingo_dump.rb

# initial setup:
# head to https://my.osc-secnum-fr1.scalingo.com/profile and create a new token
# store it in your .env like `SCALINGO_TOKEN=ab-enbxajkaxxxx`

HEADERS = {
  "Accept" => "application/json",
  "Content-Type" => "application/json",
}.freeze

bearer_token = JSON.parse(
  Typhoeus.post(
    "https://auth.scalingo.com/v1/tokens/exchange",
    headers: HEADERS,
    userpwd: ":#{ENV['SCALINGO_API_TOKEN']}"
  ).body
)["token"]

addons = JSON.parse(
  Typhoeus.get(
    "https://api.osc-secnum-fr1.scalingo.com/v1/apps/production-rdv-solidarites/addons",
    headers: HEADERS.merge({ "Authorization" => "Bearer #{bearer_token}" })
  ).body
)["addons"]
addon_db = addons.first { _1["name"] == "PostgreSQL" }
puts addon_db

bearer_token_db = JSON.parse(
  Typhoeus.post(
    "https://api.osc-secnum-fr1.scalingo.com/v1/apps/production-rdv-solidarites/addons/#{addon_db['id']}/token",
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

backup_pgsql_filename = Dir.entries(".").select { _1.ends_with?(".pgsql") }.first
backup_pgsql_path = "./#{backup_pgsql_filename}"

`dropdb rdv_solidarites_production_dump`
`createdb rdv_solidarites_production_dump`
`pg_restore -d rdv_solidarites_production_dump #{backup_pgsql_path}`
`rm #{backup_pgsql_path}`

`sed -i.backup 's/lapin_development/rdv_solidarites_production_dump/' config/database.yml`
