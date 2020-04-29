require 'dotenv/load'
require 'typhoeus'
require 'json'

if ENV['SLACK_DEPLOY_WEBHOOK_URL'].nil? || ENV['SLACK_DEPLOY_WEBHOOK_URL'] == ""
  puts "⚠️ Missing SLACK_DEPLOY_WEBHOOK_URL ! Ask a colleague"
end

Typhoeus.post(
  ENV['SLACK_DEPLOY_WEBHOOK_URL'],
  headers: {'Content-Type' => 'application/json; charset=utf-8'},
  body: JSON.dump({text: "Deployment to production is being triggered..."})
)

exec("scalingo integration-link-manual-deploy -a production-rdv-solidarites master")
