# ruby scripts/get_deployed_changes.rb --archive

# initial setup:
# head to https://github.com/settings/tokens and create a token with public_repo permission
# store it in your .env like `GITHUB_CHANGELOG_USERPWD=adipasquale:XXXX`

COLUMN_ID = 12_100_682

require "dotenv/load"
require "typhoeus"
require "json"

GITHUB_CHANGELOG_USERPWD = ENV["GITHUB_CHANGELOG_USERPWD"]

unless GITHUB_CHANGELOG_USERPWD
  puts ""
  puts "Erreur"
  puts "Vous devez avoir une variable d'environnement <GITHUB_CHANGELOG_USERPWD>"
  puts "contenant un token github permettant l'accès au `public_repo`"
  puts ""
  exit 1
end

res = Typhoeus.get(
  "https://api.github.com/projects/columns/#{COLUMN_ID}/cards",
  userpwd: GITHUB_CHANGELOG_USERPWD,
  headers: { "Accept" => "application/vnd.github.inertia-preview+json" }
)

done_cards = JSON.parse(res.body)
open_issues = []
done_cards.each do |card|
  issue = JSON.parse(Typhoeus.get(card["content_url"], userpwd: ENV["GITHUB_CHANGELOG_USERPWD"]).body)
  open_issues << issue if issue["state"] == "open"
  puts "- [#{issue['title']}](#{issue['html_url']})"
end

if ARGV[0] == "--archive"
  if open_issues.any?
    puts "closing #{open_issues.count} open issues..."
    open_issues.each do |issue|
      puts issue["url"]
      Typhoeus.patch(
        issue["url"],
        body: JSON.dump({ state: "closed" }),
        userpwd: ENV["GITHUB_CHANGELOG_USERPWD"]
      )
      puts "done!"
    end
  end

  puts "archive all #{done_cards.count} done cards..."
  done_cards.each do |card|
    Typhoeus.patch(
      card["url"],
      body: JSON.dump({ archived: true }),
      userpwd: ENV["GITHUB_CHANGELOG_USERPWD"],
      headers: { "Accept" => "application/vnd.github.inertia-preview+json" }
    )
  end
end

# commands to find column ID:

# curl \
#   -i -u adipasquale:XXXX \
#   -H "Accept: application/vnd.github.inertia-preview+json"
#   https://api.github.com/repos/betagouv/rdv-solidarites.fr/projects

# curl \
#   -i -u adipasquale:XXX \
#   -H "Accept: application/vnd.github.inertia-preview+json" \
#   https://api.github.com/projects/6111007/columns

# curl \
#   -i -u adipasquale:XXXX \
#   -H "Accept: application/vnd.github.inertia-preview+json" \
#   https://api.github.com/projects/columns/12100682/cards
