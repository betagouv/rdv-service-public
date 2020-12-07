FactoryBot.define do
  sequence(:plage_title) { |n| "Plage #{n}" }

  factory :plage_ouverture do
    organisation { create(:organisation) }
    agent { create(:agent, organisations: [organisation]) }
    lieu { create(:lieu, organisation: organisation) }

    title { generate(:plage_title) }
    sequence(:first_day) { |n| Date.today.next_week(:monday) + n.days }
    start_time { Tod::TimeOfDay.new(8) }
    end_time { Tod::TimeOfDay.new(12) }
    no_recurrence

    trait :no_recurrence do
      recurrence { nil }
    end

    trait :daily do
      recurrence { Montrose.every(:day, starts: first_day) }
    end

    trait :weekly do
      recurrence { Montrose.every(:week, on: [:monday], starts: first_day) }
    end

    trait :monthly do
      recurrence { Montrose.every(:month, starts: first_day) }
    end

    trait :weekly_by_2 do
      recurrence { Montrose.every(:week, interval: 2, starts: first_day) }
    end

    after(:build) do |plage_ouverture|
      if plage_ouverture.motifs.empty?
        plage_ouverture.motifs << create(:motif, organisation: plage_ouverture.organisation)
      end
    end
  end
end
