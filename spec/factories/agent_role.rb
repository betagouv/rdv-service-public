# frozen_string_literal: true

FactoryBot.define do
  factory :agent_role do
    agent
    organisation
    access_level { AgentRole::ACCESS_LEVEL_BASIC }

    trait :admin do
      access_level { AgentRole::ACCESS_LEVEL_ADMIN }
    end
  end
end
