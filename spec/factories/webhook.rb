FactoryBot.define do
  factory :webhook_endpoint do
    endpoint { Faker::Internet.url }
    secret { SecureRandom.base58 }
    organisation { Organisation.first || create(:organisation) }
  end
end
