class TerritoryCreationRequest < ApplicationRecord
  has_paper_trail

  belongs_to :agent

  validates :organisation_name, :territory_name, presence: true
  validates :agent_id, uniqueness: true
end
