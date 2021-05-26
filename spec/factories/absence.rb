# frozen_string_literal: true

FactoryBot.define do
  sequence(:absence_title) { |n| "Absence #{n}" }

  factory :absence do
    organisation { create(:organisation) }
    agent { create(:agent, basic_role_in_organisations: [organisation]) }

    title { generate(:absence_title) }
    first_day { Time.zone.tomorrow }
    start_time { Tod::TimeOfDay.new(10) }
    end_time { Tod::TimeOfDay.new(15, 30) }
    no_recurrence

    trait :past do
      first_day { Date.new(2019, 7, 4) }
    end

    trait :no_recurrence do
      recurrence { nil }
    end

    trait :daily do
      recurrence { Montrose.every(:day, starts: first_day) }
    end

    trait :weekly do
      recurrence { Montrose.every(:week, starts: first_day) }
    end

    trait :monthly do
      recurrence { Montrose.every(:month, starts: first_day) }
    end

    trait :every_two_weeks do
      recurrence { Montrose.every(:week, interval: 2, starts: first_day) }
    end
  end
end
