# frozen_string_literal: true

class AgentTerritorialAccessRight < ApplicationRecord
  belongs_to :agent
  belongs_to :territory
end
