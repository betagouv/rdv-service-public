FactoryBot.define do
  sequence(:plage_title) { |n| "Plage #{n}" }

  factory :plage_ouverture do
    title { generate(:plage_title) }
    organisation { Organisation.first || create(:organisation) }
    first_day { Time.zone.now }
    start_time { Tod::TimeOfDay.new(8) }
    end_time { Tod::TimeOfDay.new(12) }
    no_recurrence

    trait :no_recurrence do
      recurrence { PlageOuverture::RECURRENCES[:never] }
    end

    trait :weekly do
      recurrence { PlageOuverture::RECURRENCES[:weekly] }
    end

    trait :weekly_by_2 do
      recurrence { PlageOuverture::RECURRENCES[:weekly_by_2] }
    end

    after(:build) do |plage_ouverture|
      plage_ouverture.motifs << (Motif.first || create(:motif))
    end
  end
end
