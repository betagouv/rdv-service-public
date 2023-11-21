FactoryBot.define do
  factory :sector do
    territory
    name { Faker::Address.community }
    human_id { "#{name[0..10]}-#{SecureRandom.alphanumeric[0..10]}".parameterize }
  end
end
