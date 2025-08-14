FactoryBot.define do
  factory :access_token, class: Doorkeeper::AccessToken do
    scopes { ["write"] }
    application { create(:oauth_application) }
  end
end
