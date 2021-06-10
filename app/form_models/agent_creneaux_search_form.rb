# frozen_string_literal: true

class AgentCreneauxSearchForm
  include ActiveModel::Model

  attr_accessor :organisation_id, :service_id, :motif_id, :agent_ids, :user_ids, :lieu_ids, :context
  attr_writer :from_date

  validates :organisation_id, :motif_id, presence: true

  def organisation
    Organisation.find_by(id: organisation_id)
  end

  def service
    Service.find_by(id: service_id)
  end

  def motif
    organisation.motifs.find_by(id: motif_id)
  end

  def users
    organisation.users.where(id: user_ids)
  end

  def agents
    organisation.agents.where(id: agent_ids)
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
