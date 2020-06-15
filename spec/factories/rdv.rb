FactoryBot.define do
  factory :rdv do
    duration_in_min { 45 }
    starts_at { Time.zone.now }
    lieu { build(:lieu) }
    organisation { Organisation.first || create(:organisation) }
    motif { Motif.first || build(:motif) }
    users { [User.first || build(:user)] }
    agents { [build(:agent)] }
    notes { "Une jolie note." }
    trait :by_phone do
      motif { build(:motif, :by_phone) }
      lieu { nil }
    end
    trait :random_start do
      starts_at { Faker::Time.between(from: 10.days.ago, to: 3.month.since) }
    end
    trait :future do
      starts_at { 2.days.since }
    end
    trait :past do
      starts_at { 2.days.ago }
    end
    trait :at_home do
      motif { build(:motif, :at_home) }
      lieu { nil }
    end
    trait :excused do
      cancelled_at { 2.days.ago }
      status { 'excused' }
    end
  end
end
