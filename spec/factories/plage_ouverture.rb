FactoryBot.define do
  sequence(:plage_title) { |n| "Plage #{n}" }

  factory :plage_ouverture do
    title { generate(:plage_title) }
    organisation { Organisation.first || create(:organisation) }
    first_day { Date.new(2019, 7, 22) }
    pro { Pro.first || create(:pro) }
    start_time { Tod::TimeOfDay.new(8) }
    end_time { Tod::TimeOfDay.new(12) }
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

    trait :weekly_by_2 do
      recurrence { Montrose.every(2.weeks).to_json }
    end

    after(:build) do |plage_ouverture|
      plage_ouverture.motifs << (Motif.first || create(:motif))
    end
  end
end
