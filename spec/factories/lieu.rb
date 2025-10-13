FactoryBot.define do
  sequence(:lieu_name) { |n| "Lieu n°#{n}" }
  sequence(:address) { |n| "#{n} rue de l'adresse, Ville, 12345" }

  factory :lieu do
    organisation

    name { generate(:lieu_name) }
    address { generate(:address) }
    latitude { 38.8951 }
    longitude { -77.0364 }
    availability { :enabled }

    trait :single_use do
      availability { :single_use }
    end
    trait :disabled do
      availability { :disabled }
    end
    trait :enabled do
      availability { :enabled }
    end
  end
end
