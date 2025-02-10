FactoryBot.define do
  factory :oauth_application, class: Doorkeeper::Application do
    name { "Démarches Simplifiées" }
    uid { "fake_app_id" }
    logo_base64 { "" }
  end
end
