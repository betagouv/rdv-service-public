class RdvPlan < ApplicationRecord
  belongs_to :agent
  belongs_to :motif
  belongs_to :lieu, optional: true
  belongs_to :rdv_agent, class_name: "Agent", optional: true

  has_many :participations, class_name: "RdvPlanParticipation", dependent: :destroy
  has_many :users, through: :participations

  delegate :organisation, to: :motif
end
