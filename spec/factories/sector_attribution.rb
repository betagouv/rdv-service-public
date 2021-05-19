# frozen_string_literal: true

FactoryBot.define do
  factory :sector_attribution do
    sector
    organisation
    level { SectorAttribution::LEVEL_ORGANISATION }

    trait :level_organisation do
      level { SectorAttribution::LEVEL_ORGANISATION }
    end

    trait :level_agent do
      level { SectorAttribution::LEVEL_AGENT }
      agent { build(:agent, organisations: [organisation]) }
    end
  end
end
