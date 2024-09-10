FactoryBot.define do
  sequence(:absence_title) { |n| "Indisponibilité #{n}" }

  factory :absence do
    agent { association(:agent) }

    title { generate(:absence_title) }
    first_day { Time.zone.tomorrow }
    start_time { Tod::TimeOfDay.new(10) }
    end_time { Tod::TimeOfDay.new(15, 30) }
    no_recurrence

    trait :no_recurrence do
      recurrence { nil }
    end

    trait :weekly do
      recurrence { Montrose.every(:week, on: [:monday], starts: first_day, interval: 1) }
    end

    trait :monthly do
      # first_day.wday est le jour dans la semaine (par exemple 3 pour le mercredi)
      # first_day.mday/2 est le numéro de la semaine (par exemple la 2ème semaine du mois)
      recurrence { Montrose.every(:month, starts: first_day, day: { first_day.wday => [first_day.mday / 7] }, interval: 1) }
    end

    trait :every_two_weeks do
      recurrence { Montrose.every(:week, on: [:monday], starts: first_day, interval: 2) }
    end
  end
end
