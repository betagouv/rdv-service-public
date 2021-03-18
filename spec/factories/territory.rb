FactoryBot.define do
  sequence(:territory_name) { |n| "Territoire n°#{n}" }
  sequence(:departement_number) { |n| ((10 + n) % 100).to_s }

  factory :territory do
    name { generate(:territory_name) }
    departement_number { generate(:departement_number) }
  end
end
