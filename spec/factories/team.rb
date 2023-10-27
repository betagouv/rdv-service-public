FactoryBot.define do
  factory :team do
    territory { association(:territory) }
    name { Faker::Name.name }
  end
end
