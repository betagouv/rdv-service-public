class RdvPlan < ApplicationRecord
  belongs_to :planning_agent, class_name: "Agent"
  belongs_to :user

  belongs_to :rdv_agent, class_name: "Agent", optional: true
  belongs_to :motif, optional: true
  belongs_to :lieu, optional: true

  delegate :organisation, to: :motif

  def create_rdv(user_attributes:, participation_attributes:)
    user.update!(user_attributes)

    rdv = Rdv.create(
      agents: [rdv_agent],
      participations: [Participation.new(participation_attributes.merge(user_id: user.id))],
      motif: motif,
      organisation: organisation,
      lieu: lieu,
      starts_at: starts_at,
      created_by: planning_agent,
      ends_at: starts_at + motif.default_duration_in_min.minutes
    )

    if rdv.persisted?
      Notifiers::RdvCreated.perform_with(rdv, planning_agent)
    end

    rdv
  end
end
