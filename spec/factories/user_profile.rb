FactoryBot.define do
  factory :user_profile do
    user
    organisation
    notes { nil }
    logement { :locataire }
  end
end
