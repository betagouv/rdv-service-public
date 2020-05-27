FactoryBot.define do
  factory :rdv do
    duration_in_min { 45 }
    starts_at { Time.zone.now }
    location { "10 rue de la Ferronerie 44100 Nantes" }
    organisation { Organisation.first || create(:organisation) }
    motif { Motif.first || build(:motif) }
    users { [User.first || build(:user)] }
    agents { [build(:agent)] }
    notes { "Une jolie note." }
    trait :by_phone do
      motif { build(:motif, :by_phone) }
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
    end
    trait :excused do
      cancelled_at { 2.days.ago }
      status { 'excused' }
    end
    trait :without_notify_created_callback do
      after(:build) { |rdv| rdv.class.skip_callback(:create, :after, :notify_rdv_created) }
      after(:create) { |rdv| rdv.class.set_callback(:create, :after, :notify_rdv_created) }
    end
  end
end
