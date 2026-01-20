# Usage: bin/rails runner spec/fixtures/files/update_docs_numerique_changelog_fixtures.rb

FIXTURES_DIR = File.dirname(__FILE__)
NB_DOCS = 3

connection = Faraday.new(url: DocsNumeriqueChangelog::BASE_URL) do |f|
  f.response :json
end

# Fetch children and keep only first NB_DOCS
children = connection.get("documents/#{DocsNumeriqueChangelog::PARENT_DOCUMENT_ID}/children/").body
children["results"] = children["results"].first(NB_DOCS)
children["results"].each { |doc| doc.delete("abilities") }
children["count"] = NB_DOCS

File.write("#{FIXTURES_DIR}/docs_numerique_changelog_children.json", JSON.pretty_generate(children))
puts "Updated docs_numerique_changelog_children.json"

# Fetch content for each document
children["results"].each do |doc|
  content = connection.get("documents/#{doc['id']}/content/", content_format: "html").body
  safe_id = doc["id"].to_s[0, 8].gsub(/[^0-9A-Za-z_-]/, "")
  filename = "docs_numerique_changelog_content_#{safe_id}.json"
  File.write("#{FIXTURES_DIR}/#{filename}", JSON.pretty_generate(content))
  puts "Updated #{filename}"
end
