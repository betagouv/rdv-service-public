FactoryBot.define do
  factory :team do
    territory { association(:territory) }
    name { Faker::Team.name }
  end
end
