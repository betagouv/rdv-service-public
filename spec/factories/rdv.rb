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
      sequence :starts_at do |n|
        d = [
          "2020-03-01 10:30",
          "2019-02-10 15:05",
          "2020-06-17 10:00",
          "2020-12-01 07:30",
          "2021-10-01 11:30",
          "2020-07-10 12:45",
          "2020-01-13 09:10",
          "2020-08-03 17:30",
          "2020-11-20 16:05",
          "2020-04-01 15:35",
        ][n % 10]
        DateTime.parse(d).in_time_zone
      end
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
      status { "excused" }
    end
  end
end
