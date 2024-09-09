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

    trait :daily do # Cette option n'existe pas dans l'interface, on pourrait simplifier le code en la supprimant
      recurrence { Montrose.every(:day, starts: first_day) }
    end

    trait :weekly do
      recurrence { Montrose.every(:week, on: [:monday], starts: first_day) }
    end

    trait :monthly do
      recurrence { Montrose.every(:month, starts: first_day) }
    end

    trait :every_two_weeks do
      recurrence { Montrose.every(:week, interval: 2, starts: first_day) }
    end
  end
end
