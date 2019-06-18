class Rdv::FirstStep
  include ActiveModel::Model

  attr_accessor :evenement_type, :organisation, :duration_in_min, :start_at, :user
  validates :evenement_type, :organisation, presence: true

  def rdv
    Rdv.new(organisation: organisation,
      evenement_type: evenement_type,
      user: user,
      duration_in_min: duration_in_min,
      start_at: start_at,
      name: "#{user&.full_name} <> #{evenement_type&.name}")
  end

  def to_query
    {
      evenement_type_id: evenement_type&.id,
      organisation_id: organisation&.id,
      duration_in_min: duration_in_min,
      start_at: start_at&.to_s,
      user_id: user&.id,
    }
  end
end
