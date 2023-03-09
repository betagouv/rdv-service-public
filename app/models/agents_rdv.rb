# frozen_string_literal: true

class AgentsRdv < ApplicationRecord
  include Outlook::Synchronizable

  # Relations
  belongs_to :rdv, touch: true
  belongs_to :agent

  scope :future, -> { includes(:rdv).where(rdv: { starts_at: Time.zone.now.. }) }

  # Validation
  # Uniqueness validation doesn’t work with nested_attributes, see https://github.com/rails/rails/issues/4568
  # We do have on a DB constraint.
  validates :agent_id, uniqueness: { scope: :rdv_id }

  # Hooks
  after_commit :update_unknown_past_rdv_count
  ## -

  delegate :cancelled?, :soft_deleted?, :users, to: :rdv

  def update_unknown_past_rdv_count
    agent.update_unknown_past_rdv_count!
  end
end
