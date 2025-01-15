FactoryBot.define do
  factory :access_token, class: Doorkeeper::AccessToken do
    scopes { ["write"] }
  end
end
