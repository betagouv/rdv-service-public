FactoryBot.define do
  factory :user_profile do
    user
    organisation
    logement { UserProfile.locataire }
  end
end
