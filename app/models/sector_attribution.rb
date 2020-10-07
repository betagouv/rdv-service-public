class SectorAttribution < ApplicationRecord
  LEVEL_ORGANISATION = "organisation".freeze
  LEVEL_AGENT = "agent".freeze
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
end
