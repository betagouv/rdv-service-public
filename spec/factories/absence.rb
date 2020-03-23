FactoryBot.define do
  sequence(:absence_title) { |n| "Absence #{n}" }

  factory :absence do
    title { generate(:absence_title) }
    organisation { Organisation.first || create(:organisation) }
    first_day { Date.new(2019, 7, 4) }
    end_day { Date.new(2019, 8, 4) }
    agent { Agent.first || create(:agent) }
    start_time { Tod::TimeOfDay.new(10) }
    end_time { Tod::TimeOfDay.new(15, 30) }
    no_recurrence

    trait :no_recurrence do
      recurrence { nil }
    end

    trait :daily do
      recurrence { Montrose.every(:day) }
    end

    trait :weekly do
      recurrence { Montrose.weekly.to_json }
    end

    trait :monthly do
      recurrence { Montrose.monthly.to_json }
    end

    trait :weekly_by_2 do
      recurrence { Montrose.every(2.weeks).to_json }
    end
  end
end
