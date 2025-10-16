class AgentsRdv < ApplicationRecord
  include Outlook::EventSerializerAndListener
  include Rdv::CaldavConcern

  # Relations
  belongs_to :rdv, touch: true
  belongs_to :agent

  # Validation
  # Uniqueness validation doesn’t work with nested_attributes, see https://github.com/rails/rails/issues/4568
  # We do have on a DB constraint.
  validates :agent_id, uniqueness: { scope: :rdv_id }

  # Hooks
  after_commit :update_unknown_past_rdv_count
  # voir Outlook::EventSerializerAndListener et Rdv::CaldavConcern pour d'autres callbacks

  # A DÉPLACER

  def update_unknown_past_rdv_count
    agent.update_unknown_past_rdv_count!
  end
end
