FactoryBot.define do
  sequence(:lieu_name) { |n| "Lieu n°#{n}" }

  factory :lieu do
    name { generate(:lieu_name) }
    organisation { Organisation.first || create(:organisation) }
    address { "1 rue de l'adresse, 12345 Ville" }
    telephone { "0123456789" }
    horaires { "Du lundi au vendredi, de 10h à 18h" }
  end
end
