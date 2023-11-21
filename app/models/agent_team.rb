class AgentTeam < ApplicationRecord
  # Relations
  belongs_to :agent
  belongs_to :team
end
