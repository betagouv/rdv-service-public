FactoryBot.define do
  factory :webhook_endpoint do
    transient do
      organisations { [build(:organisation)] }
    end
    after(:build) do |webhook_endpoint, evaluator|
      evaluator.organisations.each do |organisation|
        webhook_endpoint.webhook_organisations.build(organisation:)
      end
    end

    target_url { Faker::Internet.url }
    secret { SecureRandom.base58 }
  end
end
