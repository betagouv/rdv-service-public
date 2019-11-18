FactoryBot.define do
  factory :rdv do
    name { "Michel Lapin <> Vaccination" }
    duration_in_min { 45 }
    starts_at { Time.zone.local(2019, 7, 4, 15, 0) }
    location { "10 rue de la Ferronerie 44100 Nantes" }
    organisation { Organisation.first || create(:organisation) }
    motif { build(:motif) }
    users { [build(:user)] }
    agents { [build(:agent)] }
    trait :by_phone do
      motif { build(:motif, :by_phone) }
    end
  end
end
