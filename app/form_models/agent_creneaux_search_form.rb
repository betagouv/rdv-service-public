class AgentCreneauxSearchForm
  include ActiveModel::Model

  attr_accessor :organisation_id, :motif_id, :agent_ids, :user_ids, :lieu_ids
  attr_writer :from_date

  validates :organisation_id, :motif, presence: true

  def organisation
    Organisation.find_by(id: organisation_id)
  end

  def motif
    organisation.motifs.find(motif_id)
  end

  def users
    organisation.users.where(id: user_ids)
  end

  def agents
    organisation.agents.where(id: agent_ids)
  end

  def lieux
    f_lieux = organisation.lieux
    f_lieux = f_lieux.where(id: lieu_ids) if lieu_ids.present?
    f_lieux = f_lieux.for_motif(motif) if lieu_ids.empty?
    f_lieux = f_lieux.where(id: PlageOuverture.where(agent_id: agent_ids).pluck(:lieu_id)) if agent_ids.any?
    f_lieux.ordered_by_name
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
