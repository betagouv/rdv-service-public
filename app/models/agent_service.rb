class AgentService < ApplicationRecord
  has_paper_trail

  belongs_to :agent
  belongs_to :service

  validates :service_id, uniqueness: { scope: :agent_id }
end
