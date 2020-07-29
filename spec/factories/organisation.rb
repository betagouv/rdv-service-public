FactoryBot.define do
  sequence(:orga_name) { |n| "Organisation n°#{n}" }

  factory :organisation do
    name { generate(:orga_name) }
    departement { '92' }
  end
end
