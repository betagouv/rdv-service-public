FactoryBot.define do
  factory :operator_manager, class: OperatorManager do
    operator
    email { Faker::Internet.unique.email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
  end
end
