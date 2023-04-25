# frozen_string_literal: true

FactoryBot.define do
  sequence(:agent_email) { |n| "agent_#{n}@lapin.fr" }

  factory :agent do
    service { association(:service) }
    email { generate(:agent_email) }
    uid { email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password { "password" }
    confirmed_at { Time.zone.parse("2020-07-30 10:30").in_time_zone }
    invitation_accepted_at { Time.zone.parse("2020-07-30 10:30").in_time_zone }

    transient do
      basic_role_in_organisations { [] }
    end

    transient do
      admin_role_in_organisations { [] }
    end

    transient do
      role_in_territories { [] }
    end

    after(:create) do |agent, evaluator|
      evaluator.basic_role_in_organisations.each do |organisation|
        create :agent_role, agent: agent, organisation: organisation
      end
      evaluator.admin_role_in_organisations.each do |organisation|
        create :agent_role, :admin, agent: agent, organisation: organisation
      end
      evaluator.role_in_territories.each do |territory|
        create :agent_territorial_role, agent: agent, territory: territory
      end
    end

    trait :with_basic_org do
      basic_role_in_organisations { [build(:organisation)] }
    end
    trait :not_confirmed do
      confirmed_at { nil }
    end
    trait :invitation_not_accepted do
      invitation_token { "blah" }
      invitation_created_at { 2.days.ago }
      invitation_accepted_at { nil }
      confirmed_at { nil }
    end
    trait :secretaire do
      service { Service.find_by(name: Service::SECRETARIAT) || build(:service, :secretariat) }
    end
    trait :cnfs do
      service { Service.find_by(name: Service::CONSEILLER_NUMERIQUE) || build(:service, :conseiller_numerique) }
    end
  end
end
