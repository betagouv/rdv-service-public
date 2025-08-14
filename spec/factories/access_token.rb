FactoryBot.define do
  factory :access_token, class: Doorkeeper::AccessToken do
    scopes { ["write"] }
    application { create(:oauth_application) }
    refresh_token { "fake-refresh-token" }
  end
end
