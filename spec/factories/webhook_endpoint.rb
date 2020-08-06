FactoryBot.define do
  factory :webhook_endpoint do
    organisation { create(:organisation) }

    target_url { Faker::Internet.url }
    secret { SecureRandom.base58 }
  end
end
