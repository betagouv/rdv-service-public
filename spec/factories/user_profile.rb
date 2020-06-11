FactoryBot.define do
  factory :user_profile do
    user
    organisation
    notes { "Notes libres" }
    logement { 'locataire' }
  end
end
