FactoryBot.define do
  factory :operator, class: Operator do
    name { "Operator #{Faker::Company.unique.name}" }
  end
end
