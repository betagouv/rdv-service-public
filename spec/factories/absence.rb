FactoryBot.define do
  factory :absence do
    organisation { Organisation.first || create(:organisation) }
    agent { Agent.first || create(:agent) }
    first_day { Date.new(2019, 7, 4) }
    start_time { Tod::TimeOfDay.new(15) }
    end_time { Tod::TimeOfDay.new(15, 30) }
    no_recurrence

    trait :no_recurrence do
      recurrence { nil }
    end
  end
end
