FactoryBot.define do
  factory :agent_territorial_access_right do
    agent
    territory

    trait :full_rights do
      full_rights { true }
    end
  end
end
