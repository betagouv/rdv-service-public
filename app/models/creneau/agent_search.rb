class Creneau::AgentSearch
  include ActiveModel::Model

  attr_accessor :organisation_id, :motif_id, :lieu_id
  attr_writer :from_date, :agent_ids, :lieu_ids

  validates :organisation_id, :motif_id, presence: true

  def organisation
    Organisation.find_by(id: organisation_id)
  end

  def motif
    organisation.motifs.find_by(id: motif_id)
  end

  def agents
    organisation.agents.where(id: agent_ids)
  end

  def lieu
    organisation.lieux.find_by(id: lieu_id)
  end

  def lieux
    if lieu_ids.any?
      organisation.lieux.where(id: lieu_ids)
    else
      organisation.lieux.for_motif(motif)
    end
  end

  def lieu_ids
    @lieu_ids&.reject(&:blank?)
  end

  def agent_ids
    @agent_ids&.reject(&:blank?)
  end

  def from_date
    Date.parse(@from_date)
  rescue StandardError
    Time.zone.today
  end
end
