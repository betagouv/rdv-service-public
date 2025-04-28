FactoryBot.define do
  factory :oauth_application, class: OauthApplication do
    name { "Démarches Simplifiées" }
    uid { "fake_app_id" }
    logo_base64 { "" }
    redirect_uri { "http://localhost:4567/omniauth/rdvservicepublic/callback\nhttps://demo.demarches-simplifiees.fr/omniauth/rdvservicepublic/callback" }
  end
end
