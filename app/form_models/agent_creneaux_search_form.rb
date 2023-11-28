class AgentCreneauxSearchForm
  include ActiveModel::Model

  attr_accessor :organisations, :service_id, :motif_typology_slug, :agent_ids, :team_ids, :user_ids, :lieu_ids, :context
  attr_writer :from_date

  validates :organisations, :motif_typology_slug, presence: true

  def service
    Service.find_by(id: service_id)
  end

  def motif_criteria_hash
    Motif.typology_hash_from_slug(motif_typology_slug)
  end

  def motifs
    non_name_criteria = motif_criteria_hash.slice(:location_type, :service_id, :collectif)
    @motifs ||= Motif.active
      .where(organisation: organisations)
      .where(non_name_criteria)
      .with_name_slug(motif_criteria_hash[:name_slug])
  end

  def first_motif_matching_criteria
    motifs.first
  end

  def users
    User.where(id: user_ids, organisations: organisations)
  end

  def teams
    Team.where(id: team_ids, organisations: organisations)
  end

  def date_range
    from_date..(from_date + 6.days)
  end

  def from_date
    Date.parse(@from_date)
  rescue StandardError
    Time.zone.today
  end
end
