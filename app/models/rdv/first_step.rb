class Rdv::FirstStep
  include ActiveModel::Model

  attr_accessor :motif, :organisation_id, :duration_in_min, :starts_at, :location, :users, :agents
  validates :motif, :organisation_id, presence: true

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
