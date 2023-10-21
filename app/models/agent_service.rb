# frozen_string_literal: true

class AgentService < ApplicationRecord
  belongs_to :agent
  belongs_to :service
end
