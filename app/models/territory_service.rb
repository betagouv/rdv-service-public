class TerritoryService < ApplicationRecord
  has_paper_trail

  belongs_to :territory
  belongs_to :service

  validates :service_id, uniqueness: { scope: :territory_id }
end
