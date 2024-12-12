class RdvPlan < ApplicationRecord
  belongs_to :agent
  belongs_to :motif

  has_many :rdv_plan_participations
  has_many :users, through: :rdv_plan_participations

  delegate :organisation, :service_id, to: :motif

  def lieu_ids
    [lieu_id].compact
  end

  def agent_ids
    []
  end

  def team_ids
    []
  end

  def date_range
    (from_date..(from_date + 6.days))
  end

  def from_date
    Time.zone.now.to_date
  end

  def context
    nil
  end
end
