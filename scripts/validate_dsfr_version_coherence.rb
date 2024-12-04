# Teste la cohérence entre les numéros de versions :
# - du package `dsfr` installé via yarn
# - du lien symbolique depuis public
# - et des chemins dans les helpers via la config rails
#
# appelé dans /.github/workflows/ci.yml

require "json"

yarn_lock_content = File.read("yarn.lock")
version_match = yarn_lock_content.match(%r{@gouvfr/dsfr@[^:]+:\n\s+version\s+"([^"]+)"})
raise "Error fetching dsfr version from yarn.lock" unless version_match

version = version_match[1]
puts "✅ current @gouvfr/dsfr node package version is #{version}"

symlinks = Dir.glob("public/dsfr-v*")
if symlinks.size == 1 && File.symlink?(symlinks.first) && symlinks.first == "public/dsfr-v#{version}"
  puts "✅ Single symbolic link found for version #{version}"
else
  raise "Error: Expected one symbolic link for version #{version}, found #{symlinks}"
end

# on ne peut pas appeler Rails.configuration.x.dsfr.version ici car on lance ce script dans la CI
# sans avoir installé les gems et configuré l’environnement
rails_config_versions = File
  .read("config/application.rb")
  .scan(/config.x.dsfr.version = "(\d+\.\d+\.\d+)"/)
  .flatten
  .uniq
if rails_config_versions.size == 1 && rails_config_versions.first == version
  puts "✅ Correct version used in Rails.configuration.x.dsfr.version"
else
  raise "Error: incorrect version(s) used in Rails.configuration.x.dsfr.version : #{rails_config_versions}"
end
