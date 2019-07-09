FactoryBot.define do
  factory :rdv do
    name { "Michel Lapin <> Vaccination" }
    duration_in_min { 45 }
    start_at { Time.zone.local(2019, 0o7, 4, 15, 0) }
    organisation { Organisation.first || build(:organisation) }
    motif { build(:motif) }
    user { build(:user) }
  end
end
