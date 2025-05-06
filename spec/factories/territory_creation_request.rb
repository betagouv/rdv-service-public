FactoryBot.define do
  factory :territory_creation_request do
    territory_name { "Commune de Montreuil" }
    organisation_name { "CCAS de Montreuil" }
    service_name { "Action Sociale" }
    agent { association(:agent) }
  end
end
