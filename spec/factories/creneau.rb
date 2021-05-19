# frozen_string_literal: true

FactoryBot.define do
  factory :creneau do
    starts_at { 10.days.from_now }
    motif

    trait :does_not_respect_min_booking_delay do
      motif { build(:motif, min_booking_delay: 14.days) }
    end

    trait :does_not_respect_max_booking_delay do
      motif { build(:motif, max_booking_delay: 7.days) }
    end

    trait :respects_booking_delays do
      motif { build(:motif, min_booking_delay: 1.day, max_booking_delay: 1.month) }
    end
  end
end
