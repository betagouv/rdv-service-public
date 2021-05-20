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
