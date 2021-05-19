# frozen_string_literal: true

FactoryBot.define do
  factory :agent_role do
    agent
    organisation
    level { AgentRole::LEVEL_BASIC }

    trait :admin do
      level { AgentRole::LEVEL_ADMIN }
    end
  end
end
