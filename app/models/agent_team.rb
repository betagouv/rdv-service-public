# frozen_string_literal: true

class AgentTeam < ApplicationRecord
  # Relations
  belongs_to :agent
  belongs_to :team
end
