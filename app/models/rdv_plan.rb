class RdvPlan < ApplicationRecord
  belongs_to :agent
  belongs_to :motif
  belongs_to :lieu, optional: true
  belongs_to :rdv_agent, class_name: "Agent", optional: true

  has_many :participations, class_name: "RdvPlanParticipation", dependent: :destroy
  has_many :users, through: :participations

  delegate :organisation, to: :motif

  def user
    # Pour le moment, on ne gère pas le cas de l'inscription de plusieurs usagers
    users.first
  end

  def create_rdv(current_agent, user_attributes:, participation:)
    users.first.update!(user_attributes)

    rdv = Rdv.create(
      agents: [agent],
      participations: [Participation.new(participation.merge(user_id: user.id))],
      motif: motif,
      organisation: organisation,
      lieu: lieu,
      starts_at: starts_at,
      created_by: current_agent,
      ends_at: starts_at + motif.default_duration_in_min.minutes
    )

    if rdv.persisted
      Notifiers::RdvCreated.perform_with(rdv, current_agent)
    end

    rdv
  end
end
