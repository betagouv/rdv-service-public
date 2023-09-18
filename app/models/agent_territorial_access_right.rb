# frozen_string_literal: true

class AgentTerritorialAccessRight < ApplicationRecord
  # Mixins
  has_paper_trail

  # Relations
  belongs_to :agent
  belongs_to :territory
end
