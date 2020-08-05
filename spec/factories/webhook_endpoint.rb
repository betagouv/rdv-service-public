FactoryBot.define do
  factory :webhook_endpoint do
    target_url { Faker::Internet.url }
    secret { SecureRandom.base58 }
    organisation { create(:organisation) }
  end
end
