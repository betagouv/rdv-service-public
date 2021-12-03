class AgentTeam < ActiveRecord::Base
  belongs_to :agent
  belongs_to :team
end
