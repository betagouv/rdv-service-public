class RdvPlan < ApplicationRecord
  belongs_to :planning_agent, class_name: "Agent"
  belongs_to :user

  belongs_to :rdv_agent, class_name: "Agent", optional: true
  belongs_to :motif, optional: true
  belongs_to :lieu, optional: true
  belongs_to :rdv, optional: true

  delegate :organisation, to: :motif

  # TODO: ajouter validation de synchro avec location type du motif
  enum :location_type, { public_office: "public_office", phone: "phone", home: "home", visio: "visio" }

  def create_rdv(user_attributes:, participation_attributes:)
    # TODO: le changement d'adresse email ne marche pas toujours, probablement à cause de unconfirmed_email. A vérifier.
    user.update!(user_attributes)

    rdv = Rdv.create(
      agents: [rdv_agent],
      participations: [Participation.new(participation_attributes.merge(user_id: user.id))],
      motif: motif,
      organisation: organisation,
      lieu: lieu,
      starts_at: starts_at,
      created_by: planning_agent,
      ends_at: starts_at + (duration_in_minutes || motif.default_duration_in_min).minutes
    )

    if rdv.persisted?
      update(rdv: rdv)
      Notifiers::RdvCreated.perform_with(rdv, planning_agent)
    end

    rdv
  end

  def modalite; end
end
