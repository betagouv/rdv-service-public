class Rdv::FirstStep
  include ActiveModel::Model

  attr_accessor :motif, :organisation, :duration_in_min, :start_at, :max_users_limit, :user
  validates :motif, :organisation, presence: true

  def rdv
    Rdv.new(organisation: organisation,
      motif: motif,
      user: user,
      duration_in_min: duration_in_min,
      start_at: start_at,
      max_users_limit: max_users_limit,
      name: "#{user&.full_name} <> #{motif&.name}")
  end

  def to_query
    {
      motif_id: motif&.id,
      organisation_id: organisation&.id,
      duration_in_min: duration_in_min,
      start_at: start_at&.to_s,
      user_id: user&.id,
      max_users_limit: max_users_limit,
    }
  end
end
