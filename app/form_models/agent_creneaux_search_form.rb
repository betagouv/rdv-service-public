class AgentCreneauxSearchForm
  include ActiveModel::Model

  attr_accessor :organisation_id, :service_id, :motif_criteria_json, :agent_ids, :team_ids, :user_ids, :lieu_ids, :context
  attr_writer :from_date

  validates :organisation_id, :motif_criteria, presence: true

  def organisation
    Organisation.find_by(id: organisation_id)
  end

  def service
    Service.find_by(id: service_id)
  end

  def motif_criteria
    @motif_criteria ||= JSON.parse(motif_criteria_json).with_indifferent_access if motif_criteria_json.present? && JSON.parse(motif_criteria_json).present?
  end

  def motifs
    non_name_criteria = motif_criteria.slice(:location_type, :service_id, :collectif)
    @motifs ||= Motif.active.where(non_name_criteria).with_name_slug(motif_criteria[:name_slug])
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
