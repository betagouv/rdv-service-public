FactoryBot.define do
  sequence(:client_id) { |n| "fake_app_id_#{n}" }

  factory :oauth_application, class: OauthApplication do
    name { "Démarches Simplifiées" }
    uid { generate(:client_id) }
    logo_base64 { "" }
    redirect_uri { "http://localhost:4567/omniauth/rdvservicepublic/callback\nhttps://demo.demarches-simplifiees.fr/omniauth/rdvservicepublic/callback" }
  end
end
