FactoryBot.define do
  sequence(:agent_email) { |n| "agent_#{n}@lapin.fr" }

  factory :agent do
    service { create(:service) }
    email { generate(:agent_email) }
    uid { email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password { "password" }
    confirmed_at { DateTime.parse("2020-07-30 10:30").in_time_zone }

    transient do
      basic_role_in_organisations { [] }
    end

    transient do
      admin_role_in_organisations { [] }
    end

    after(:create) do |agent, evaluator|
      evaluator.basic_role_in_organisations.each do |organisation|
        create :agent_role, agent: agent, organisation: organisation
      end
      evaluator.admin_role_in_organisations.each do |organisation|
        create :agent_role, :admin, agent: agent, organisation: organisation
      end
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
      service { Service.find_by(name: "Secrétariat") || create(:service, :secretariat) }
    end
  end
end
