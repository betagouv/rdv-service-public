FactoryBot.define do
  factory :creneau do
    starts_at { 1.day.from_now }
    motif

    trait :does_not_respect_min_booking_delay do
      starts_at { 1.day.from_now }
      motif { build(:motif, min_booking_delay: 2.days) }
    end

    trait :does_not_respect_max_booking_delay do
      starts_at { 10.days.from_now }
      motif { build(:motif, max_booking_delay: 7.days) }
    end
  end
end
