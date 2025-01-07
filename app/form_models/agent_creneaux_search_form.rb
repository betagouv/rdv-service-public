class AgentCreneauxSearchForm
  include ActiveModel::Model

  attr_accessor :organisation_id, :service_id, :motif_id, :agent_ids, :team_ids, :user_ids, :lieu_ids, :context
  attr_writer :from_date

  validates :organisation_id, :motif, presence: true

  def self.build_from(rdv_plan, from_date: nil)
    new(
      organisation_id: rdv_plan.motif.organisation_id,
      service_id: rdv_plan.motif.service_id,
      motif_id: rdv_plan.motif_id,
      agent_ids: [],
      team_ids: [],
      user_ids: rdv_plan.user_ids,
      from_date: from_date 

    )
  end

  def organisation
    Organisation.find_by(id: organisation_id) if organisation_id.present?
  end

  def service
    Service.find_by(id: service_id) if service_id.present?
  end

  def motif
    organisation.motifs.find_by(id: motif_id) if motif_id.present?
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
