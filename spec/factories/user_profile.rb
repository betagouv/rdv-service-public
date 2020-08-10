FactoryBot.define do
  factory :user_profile do
    user
    organisation
    logement { :locataire }
  end
end
