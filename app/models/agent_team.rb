class AgentTeam < ApplicationRecord
  has_paper_trail

  # Relations
  belongs_to :agent
  belongs_to :team
end
