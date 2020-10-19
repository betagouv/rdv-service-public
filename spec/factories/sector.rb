FactoryBot.define do
  factory :sector do
    name { Faker::Address.community }
    departement { "62" }
    human_id { name[0..10].parameterize }
  end
end
