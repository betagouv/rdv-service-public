# frozen_string_literal: true

class AgentTeam < ApplicationRecord
  belongs_to :agent
  belongs_to :team
end
