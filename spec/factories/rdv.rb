FactoryBot.define do
  factory :rdv do
    name { "Rdv Michel Lapin" }
    duration_in_min { 45 }
    start_at { Time.zone.local(2019, 0o7, 4, 15, 0) }
    organisation { build(:organisation) }
  end
end
