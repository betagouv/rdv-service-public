FactoryBot.define do
  factory :user_profile do
    user
    organisation
    notes { "Notes libres" }
    logement { UserProfile.locataire }
  end
end
