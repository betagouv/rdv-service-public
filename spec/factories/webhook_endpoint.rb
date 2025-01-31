FactoryBot.define do
  factory :webhook_endpoint do
    transient do
      organisations { [build(:organisation)] }
    end
    after(:build) do |webhook_endpoint, evaluator|
      raise "This factory only allows passing organisations, not the territory" if webhook_endpoint.territory

      webhook_endpoint.territory = evaluator.organisations.map(&:territory).sole
      evaluator.organisations.each do |organisation|
        webhook_endpoint.webhook_organisations.build(organisation:)
      end
    end

    target_url { Faker::Internet.url }
    secret { SecureRandom.base58 }
    subscriptions { %w[rdv absence plage_ouverture] }
  end
end
