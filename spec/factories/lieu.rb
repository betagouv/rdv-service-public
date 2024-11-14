FactoryBot.define do
  factory :lieu do
    organisation

    name { Faker::Address.community }
    address { Faker::Address.full_address }
    latitude { 38.8951 }
    longitude { -77.0364 }
    availability { :enabled }
  end
end
