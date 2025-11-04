FactoryBot.define do
  factory :plage_ouverture do
    organisation { association(:organisation) }
    agent { association(:agent, basic_role_in_organisations: [organisation]) }
    lieu { association(:lieu, organisation: organisation) }

    sequence(:title) { |n| random_value_in(["Plage #{n}", nil]) }
    sequence(:first_day) do |n|
      day = Time.zone.today.next_week(:monday)
      day += 1.day if OffDays::JOURS_FERIES.include?(day) || day.saturday? || day.sunday?
      # cet algo empêche de renvoyer un jour férié et évite de renvoyer le même jour pour 2 `n` consécutifs
      (0...n).each do
        day += 1.day
        day += 1.day if OffDays::JOURS_FERIES.include?(day) || day.saturday? || day.sunday?
      end
      day
    end
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

    trait :weekly_on_monday do
      recurrence { Montrose.every(:week, on: [:monday], starts: first_day, interval: 1) }
    end

    trait :weekly_on_monday_until_next_month do
      recurrence { Montrose.every(:week, on: [:monday], starts: first_day, interval: 1, until: 1.month.from_now) }
    end

    trait :once_a_week do
      recurrence { Montrose.every(:week, starts: first_day, interval: 1, until: 2.months.from_now) }
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
