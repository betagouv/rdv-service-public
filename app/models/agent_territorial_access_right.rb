# frozen_string_literal: true

class AgentTerritorialAccessRight < ApplicationRecord
  has_paper_trail

  belongs_to :agent
  belongs_to :territory
end
