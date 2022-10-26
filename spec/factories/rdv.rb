# frozen_string_literal: true

FactoryBot.define do
  factory :rdv do
    created_at { Time.zone.parse("2020-06-5 13:51").in_time_zone }
    updated_at { Time.zone.parse("2020-06-5 13:51").in_time_zone }
    organisation { create(:organisation) }
    lieu { build(:lieu, organisation: organisation) }
    motif { build(:motif, organisation: organisation) }
    users { [build(:user, organisations: [organisation])] }
    agents { [build(:agent, organisations: [organisation])] }

    duration_in_min { 45 }
    starts_at { 3.days.from_now }

    status { "unknown" }

    trait :collectif do
      motif { build(:motif, :collectif, organisation: organisation) }
    end
    trait :at_public_office do
      motif { build(:motif, :at_public_office, organisation: organisation) }
    end
    trait :by_phone do
      motif { build(:motif, :by_phone, organisation: organisation) }
      lieu { nil }
    end
    trait :past do
      starts_at { 1.day.ago.at_noon }
    end
    trait :future do
      starts_at { 2.days.from_now.at_noon }
    end
    trait :at_home do
      motif { build(:motif, :at_home, organisation: organisation) }
      lieu { nil }
    end
    trait :excused do
      cancelled_at { Time.zone.parse("2020-01-15 10:30").in_time_zone }
      status { "excused" }
    end
  end
end
