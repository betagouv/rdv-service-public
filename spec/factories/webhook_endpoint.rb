# frozen_string_literal: true

FactoryBot.define do
  factory :webhook_endpoint do
    organisation { association(:organisation) }

    target_url { Faker::Internet.url }
    secret { SecureRandom.base58 }
  end
end
