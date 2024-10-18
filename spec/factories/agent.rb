FactoryBot.define do
  sequence(:agent_email) { |n| "agent_#{n}@lapin.fr" }

  factory :agent do
    email { generate(:agent_email) }
    uid { email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password { "Correcth0rse!" }
    confirmed_at { Time.zone.parse("2020-07-30 10:30").in_time_zone }
    invitation_accepted_at { Time.zone.parse("2020-07-30 10:30").in_time_zone }

    transient do
      service { build(:service) }
    end
    after(:build) do |agent, evaluator|
      if agent.agent_services.empty? && agent.services.empty?
        agent.services = if evaluator.service
                           [evaluator.service]
                         else
                           [build(:service)]
                         end
      end
    end

    transient do
      basic_role_in_organisations { [] }
    end

    transient do
      admin_role_in_organisations { [] }
    end

    transient do
      intervenant_role_in_organisations { [] }
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
      evaluator.intervenant_role_in_organisations.each do |organisation|
        create :agent_role, :intervenant, agent: agent, organisation: organisation
      end
      evaluator.role_in_territories.each do |territory|
        create :agent_territorial_role, agent: agent, territory: territory
      end
    end

    trait :with_basic_org do
      basic_role_in_organisations { [build(:organisation)] }
    end
    trait :with_territory_access_rights do
      agent_territorial_access_rights do
        organisations.map(&:territory_id).uniq.map do |territory_id|
          build(:agent_territorial_access_rights, agent: self, territory_id: territory_id)
        end
      end
    end
    trait :not_confirmed do
      confirmed_at { nil }
    end
    trait :invitation_not_accepted do
      sequence(:invitation_token) { |n| "invitation-t0k3n-#{n}" }
      invitation_created_at { 2.days.ago }
      invitation_sent_at { 2.days.ago }
      invitation_accepted_at { nil }
      confirmed_at { nil }
    end
    trait :secretaire do
      services { [Service.find_by(name: Service::SECRETARIAT) || build(:service, :secretariat)] }
    end
    trait :cnfs do
      services { [Service.find_by(name: Service::CONSEILLER_NUMERIQUE) || build(:service, :conseiller_numerique)] }
    end
    trait :intervenant do
      email { nil }
      uid { nil }
      first_name { nil }
      invitation_token { nil }
      invitation_created_at { nil }
      invitation_accepted_at { nil }
      after(:build) do |agent|
        if agent.organisations.any?
          agent.roles.first.update(access_level: AgentRole::ACCESS_LEVEL_INTERVENANT)
        else
          agent.roles = [build(:agent_role, access_level: AgentRole::ACCESS_LEVEL_INTERVENANT, organisation: create(:organisation))]
        end
      end
    end
  end
end
