class RdvWizard
  # Note: This model is not an ActiveRecord model, it's not persisted
  include ActiveModel::Model

  attr_accessor :motif, :organisation_id, :duration_in_min, :starts_at, :location, :users, :agents
  attr_accessor :current_step

  validates :motif, :organisation_id, presence: true
  validates :duration_in_min, :starts_at, :agents, presence: true, if: -> { current_step >= 2 }

  delegate :to_query, to: :rdv

  def rdv
    Rdv.new(organisation_id: organisation_id,
      motif: motif,
      users: users || [],
      location: location,
      agents: agents || [],
      duration_in_min: duration_in_min,
      starts_at: starts_at)
  end
end
