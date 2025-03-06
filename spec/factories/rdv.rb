FactoryBot.define do
  factory :rdv do
    organisation { association(:organisation) }
    lieu { build(:lieu, organisation: organisation) }
    agents { [build(:agent, organisations: [organisation])] }
    motif { build(:motif, organisation: organisation, service: agents.first.services.first) }

    duration_in_min { motif&.default_duration_in_min || random_value_in([15, 30, 45, 60, 90]) }
    starts_at { Faker::Time.forward(days: 7) }

    status { "unknown" }

    trait :collectif do
      motif { build(:motif, :collectif, organisation: organisation) }
    end
    trait :at_public_office do
      motif { build(:motif, :at_public_office, organisation: organisation) }
    end
    trait :by_phone do
      motif { build(:motif, :by_phone, organisation: organisation) }
      lieu { nil }
    end
    trait :past do
      starts_at { Faker::Time.backward(days: 30) }
    end
    trait :future do
      starts_at { Faker::Time.forward(days: 7) }
    end
    trait :at_home do
      motif { build(:motif, :at_home, organisation: organisation) }
      lieu { nil }
    end
    trait :excused do
      cancelled_at { 2.days.ago }
      status { "excused" }
    end

    trait(:with_fake_timestamps) do
      created_at { 2.days.ago }
      updated_at { created_at }
    end

    # by default, attach a new user when building a RDV
    transient { with_users { true } }
    trait :without_users do
      transient { with_users { false } }
    end
    after(:build) do |rdv, evaluator|
      if evaluator.with_users && rdv.users.blank? && rdv.participations.blank?
        rdv.users = [build(:user, organisations: [rdv.organisation])]
      end
    end

    after(:build) do |rdv|
      rdv.created_by ||= rdv.agents.first
      rdv.participations.each { |participation| participation.created_by ||= rdv.created_by }
    end
  end
end
