FactoryBot.define do
  factory :team do
    territory { association(:territory) }
    name { "#{Faker::Team.name} #{SecureRandom.hex(4)}" }
  end
end
