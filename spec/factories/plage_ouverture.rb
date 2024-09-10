FactoryBot.define do
  sequence(:plage_title) { |n| "Plage #{n}" }

  factory :plage_ouverture do
    organisation { association(:organisation) }
    agent { association(:agent, basic_role_in_organisations: [organisation]) }
    lieu { association(:lieu, organisation: organisation) }

    title { generate(:plage_title) }
    sequence(:first_day) { |n| Time.zone.today.next_week(:monday) + n.days }
    start_time { Tod::TimeOfDay.new(8) }
    end_time { Tod::TimeOfDay.new(12) }
    no_recurrence

    trait :no_recurrence do
      recurrence { nil }
    end

    trait :weekdays do
      recurrence do
        # Ce format de récurrence correspond à ce qu'on a en base
        Montrose.every(:week, on: %i[monday tuesday wednesday thursday friday], starts: first_day, interval: 1)
      end
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

    after(:build) do |plage_ouverture|
      if plage_ouverture.motifs.empty?
        plage_ouverture.motifs << (
          if plage_ouverture.lieu
            build(:motif, organisation: plage_ouverture.organisation)
          else
            build(:motif, :by_phone, organisation: plage_ouverture.organisation)
          end
        )
      end
    end

    trait :expired do
      # Used to avoid refresh_expired_cached callback when needed for test
      # rubocop:disable Rails/SkipsModelValidations
      after(:create) do |plage_ouverture|
        plage_ouverture.update_column(:expired_cached, true)
      end
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
