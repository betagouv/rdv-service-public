class TerritoryCreationRequest < ApplicationRecord
  has_paper_trail

  belongs_to :agent
end
