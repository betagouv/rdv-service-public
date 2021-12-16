# frozen_string_literal: true

class AgentsRdv < ApplicationRecord
  belongs_to :rdv, touch: true
  belongs_to :agent

  after_commit :update_unknown_past_rdv_count

  def update_unknown_past_rdv_count
    agent.update_unknown_past_rdv_count!
  end
end
