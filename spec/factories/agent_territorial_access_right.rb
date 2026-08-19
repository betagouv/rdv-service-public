FactoryBot.define do
  factory :agent_territorial_access_right do
    agent
    territory

    trait :territory_admin do
      territory_admin { true }
    end
  end
end
