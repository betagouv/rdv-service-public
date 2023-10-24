# frozen_string_literal: true

class AgentService < ApplicationRecord
  has_paper_trail

  belongs_to :agent
  belongs_to :service
end
