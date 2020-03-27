FactoryBot.define do
  factory :webhook do
    endpoint { Faker::Internet.url }
    organisation { Organisation.first || create(:organisation) }
  end
end
