class AgentTeam < ApplicationRecord
  has_paper_trail

  # Relations
  belongs_to :agent
  belongs_to :team

  validates :agent_id, uniqueness: { scope: :team_id }
end
