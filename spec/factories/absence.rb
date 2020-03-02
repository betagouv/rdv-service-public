FactoryBot.define do
  factory :absence do
    organisation { Organisation.first || create(:organisation) }
    agent { Agent.first || create(:agent) }
    first_day { Date.new(2019, 7, 4) }
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
