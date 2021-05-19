# frozen_string_literal: true

class SectorAttribution < ApplicationRecord
  LEVEL_ORGANISATION = "organisation"
  LEVEL_AGENT = "agent"
  LEVELS = [LEVEL_ORGANISATION, LEVEL_AGENT].freeze

  belongs_to :organisation
  belongs_to :sector
  belongs_to :agent, optional: true

  validates :level, inclusion: { in: LEVELS }
  validates :organisation, :sector, :level, presence: true
  validates :agent, presence: true, if: :level_agent?

  scope :level_agent, -> { where(level: LEVEL_AGENT) }
  scope :level_organisation, -> { where(level: LEVEL_ORGANISATION) }

  def level_agent?
    level == LEVEL_AGENT
  end

  def level_organisation?
    level == LEVEL_ORGANISATION
  end

  def self.level_agent_grouped_by_service(organisation)
    SectorAttribution
      .level_agent
      .where(organisation: organisation)
      .includes(:agent)
      .to_a
      .group_by { _1.agent.service_id }
      .transform_values do |attributions|
        {
          sectors_count: attributions.pluck(:sector_id).uniq.count,
          agents_count: attributions.pluck(:agent_id).uniq.count,
          attributions: attributions
        }
      end
  end
end
