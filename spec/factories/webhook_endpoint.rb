FactoryBot.define do
  factory :webhook_endpoint do
    organisation { association(:organisation) }

    target_url { Faker::Internet.url }
    secret { SecureRandom.base58 }

    trait :bypassing_host_validation do
      to_create do |webhook_endpoint|
        with_modified_env(ALLOWED_WEBHOOK_HOSTS: "ALLOW_ALL_HOSTS") { webhook_endpoint.save! }
      end
    end
  end
end
