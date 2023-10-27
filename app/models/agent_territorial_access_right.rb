class AgentTerritorialAccessRight < ApplicationRecord
  has_paper_trail

  belongs_to :agent
  belongs_to :territory
end
