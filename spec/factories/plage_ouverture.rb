FactoryBot.define do
  sequence(:plage_title) { |n| "Plage #{n}" }

  factory :plage_ouverture do
    title { generate(:plage_title) }
  end
end
