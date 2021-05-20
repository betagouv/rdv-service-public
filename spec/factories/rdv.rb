# frozen_string_literal: true

FactoryBot.define do
  factory :rdv do
    created_at { DateTime.parse("2020-06-5 13:51").in_time_zone }
    updated_at { DateTime.parse("2020-06-5 13:51").in_time_zone }
    organisation { create(:organisation) }
    lieu { build(:lieu, organisation: organisation) }
    motif { build(:motif, organisation: organisation) }
    users { [build(:user, organisations: [organisation])] }
    agents { [build(:agent, organisations: [organisation])] }

    duration_in_min { 45 }
    starts_at { Time.zone.now + 3.days }

    status { "unknown" }

    trait :by_phone do
      motif { build(:motif, :by_phone, organisation: organisation) }
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
          "2020-04-01 15:35"
        ][n % 10]
        DateTime.parse(d).in_time_zone
      end
    end
    trait :future do
      starts_at { 2.days.from_now.at_noon }
    end
    trait :at_home do
      motif { build(:motif, :at_home, organisation: organisation) }
      lieu { nil }
    end
    trait :excused do
      cancelled_at { DateTime.parse("2020-01-15 10:30").in_time_zone }
      status { "excused" }
    end
  end
end
