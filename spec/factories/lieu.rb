FactoryBot.define do
  sequence(:lieu_name) { |n| "Lieu n°#{n}" }
  sequence(:address) { |n| "#{n} rue de l'adresse, 12345 Ville" }

  factory :lieu do
    name { generate(:lieu_name) }
    organisation { Organisation.first || create(:organisation) }
    address { generate(:address) }
    telephone { "0123456789" }
    horaires { "Du lundi au vendredi, de 10h à 18h" }
  end
end
