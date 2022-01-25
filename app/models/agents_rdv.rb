# frozen_string_literal: true

class AgentsRdv < ApplicationRecord
  belongs_to :rdv, touch: true
  belongs_to :agent

  # Uniqueness validation doesn’t work with nested_attributes, see https://github.com/rails/rails/issues/4568
  # We do have on a DB constraint.
  validates :agent_id, uniqueness: { scope: :rdv_id }

  after_commit :update_unknown_past_rdv_count

  def update_unknown_past_rdv_count
    agent.update_unknown_past_rdv_count!
  end
end
