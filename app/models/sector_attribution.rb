class SectorAttribution < ApplicationRecord
  LEVEL_ORGANISATION = "organisation".freeze

  belongs_to :organisation
  belongs_to :sector

  validates :organisation, :sector, :level, presence: true
  validates :level, inclusion: { in: [LEVEL_ORGANISATION] }

  scope :level_organisation, -> { where(level: LEVEL_ORGANISATION) }
end
