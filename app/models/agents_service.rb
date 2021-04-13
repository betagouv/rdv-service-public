class AgentsService < ApplicationRecord
  belongs_to :agent
  belongs_to :service
end
