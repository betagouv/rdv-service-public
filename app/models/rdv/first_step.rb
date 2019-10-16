class Rdv::FirstStep
  include ActiveModel::Model

  attr_accessor :motif, :organisation_id, :duration_in_min, :starts_at, :location, :users, :pros
  validates :motif, :organisation_id, presence: true

  def rdv
    Rdv.new(organisation_id: organisation_id,
      motif: motif,
      users: users || [],
      location: location,
      pros: pros || [],
      duration_in_min: duration_in_min,
      starts_at: starts_at,
      name: "#{users&.map(&:full_name)&.to_sentence} <> #{motif&.name}")
  end

  def to_query
    {
      motif_id: motif&.id,
      location: location,
      organisation_id: organisation_id,
      duration_in_min: duration_in_min,
      starts_at: starts_at&.to_s,
      user_ids: users&.map(&:id),
      pro_ids: pros&.map(&:id),
    }
  end
end
