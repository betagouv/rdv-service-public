FactoryBot.define do
  sequence(:name) { |n| "Catégorie de motif n°#{n}" }
  sequence(:short_name) { |n| "#{n}_motif_cat" }

  factory :motif_category do
    name { generate(:name) }
    short_name { generate(:short_name) }

    trait :passeport do
      name { Api::Ants::EditorController::PASSPORT_MOTIF_CATEGORY_NAME }
    end
  end
end
