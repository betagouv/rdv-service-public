class SectorAttribution < ApplicationRecord
  # Attributes
  # TODO: make it an enum
  LEVEL_ORGANISATION = "organisation".freeze
  LEVEL_AGENT = "agent".freeze
  LEVELS = [LEVEL_ORGANISATION, LEVEL_AGENT].freeze

  # Relations
  belongs_to :organisation
  belongs_to :sector
  belongs_to :agent, optional: true

  # Validations
  validates :level, inclusion: { in: LEVELS }
  validates :level, presence: true
  validates :agent, presence: true, if: :level_agent?

  # Scopes
  scope :level_agent, -> { where(level: LEVEL_AGENT) }
  scope :level_organisation, -> { where(level: LEVEL_ORGANISATION) }

  ## -

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
      .group_by { _1.agent.services.first.id }
      .transform_values do |attributions|
        {
          sectors_count: attributions.pluck(:sector_id).uniq.count,
          agents_count: attributions.pluck(:agent_id).uniq.count,
          attributions: attributions,
        }
      end
  end
end
