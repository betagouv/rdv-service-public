class AgentCreneauxSearchForm
  include ActiveModel::Model

  attr_accessor :organisation_id, :service_id, :motif_criteria, :agent_ids, :team_ids, :user_ids, :lieu_ids, :context
  attr_writer :from_date

  validates :organisation_id, :motif_criteria, presence: true

  def organisation
    Organisation.find_by(id: organisation_id)
  end

  def service
    Service.find_by(id: service_id)
  end

  def motif_criteria_hash
    Motif.criteria_hash_from_slug(motif_criteria)
  end

  def motifs
    non_name_criteria = motif_criteria_hash.slice(:location_type, :service_id, :collectif)
    @motifs ||= Motif.active
      .where(non_name_criteria)
      .with_name_slug(motif_criteria_hash[:name_slug])
  end

  def first_motif_matching_criteria
    motifs.first
  end

  def users
    organisation.users.where(id: user_ids)
  end

  def teams
    organisation.territory.teams.where(id: team_ids)
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
