# frozen_string_literal: true

class AgentsRdv < ApplicationRecord
  # Mixins
  include Outlook::EventSerializerAndListener
  include WebhookDeliverable

  # Relations
  belongs_to :rdv, touch: true
  belongs_to :agent

  # Delegates
  delegate :organisation, to: :rdv
  delegate :webhook_endpoints, to: :organisation

  # Validation
  # Uniqueness validation doesn’t work with nested_attributes, see https://github.com/rails/rails/issues/4568
  # We do have on a DB constraint.
  validates :agent_id, uniqueness: { scope: :rdv_id }

  # Hooks
  after_commit :update_unknown_past_rdv_count
  # voir Outlook::EventSerializerAndListener pour d'autres callbacks

  def update_unknown_past_rdv_count
    agent.update_unknown_past_rdv_count!
  end
end
