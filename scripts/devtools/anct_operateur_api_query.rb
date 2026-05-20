# Ce script permet de debugger ce que retourne l’API du compte opérateur de l’ANCT pour un SIRET et un email
#
# Requirements : CLIs scalingo + http + accès scalingo à la prod
#
# usage : rails runner scripts/devtools/anct_operateur_api_query.rb --siret 59949909909912 --email "agent@commune.fr"
#

require "optparse"

options = {}
OptionParser.new do |opt|
  opt.on("--siret SIRET") { options[:siret] = _1 }
  opt.on("--email EMAIL") { options[:email] = _1 }
end.parse!

url = "https://operateurs.suite.anct.gouv.fr/api/v1.0/entitlements"

puts "getting token from scalingo…"
token = `scalingo --app production-rdv-mairie env-get ESPACE_OPERATEUR_ANCT_AUTH_TOKEN`
puts "got token from scalingo, now querying #{url}"

command = <<SH
  http GET #{url} \
    --follow \
    X-Service-Auth:"#{token}" \
    service_id==#{EspaceOperateurANCT::ApiClient::ESPACE_OPERATEUR_SERVICE_ID} \
    account_type==#{EspaceOperateurANCT::ApiClient::ACCOUNT_TYPE} \
    siret==#{options[:siret]} \
    account_email=="#{options[:email]}"
SH

exec(command)
