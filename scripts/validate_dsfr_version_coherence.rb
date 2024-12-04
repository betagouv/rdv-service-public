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
