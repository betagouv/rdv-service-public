class RdvInvitation < ApplicationRecord
  encrypts :token, deterministic: true

  has_paper_trail

  belongs_to :inviting_agent, class_name: "Agent"
  belongs_to :user

  belongs_to :motif
  belongs_to :lieu, optional: true
  belongs_to :rdv, optional: true

  delegate :organisation, to: :motif

  before_create :set_restricted_authentication_token

  def creneau_search(starts_at)
    # TODO: vérifier si starts_at doit être une Date
    CreneauxSearch::ForUser.new(
      motif: motif,
      lieu: lieu,
      user: user,
      date_range: starts_at..(starts_at + 6.days)
    )
  end

  def create_rdv_and_notify(starts_at:)
    creneau = creneaux_search(starts_at).creneaux.first

    if creneau.nil?
      errors.add(:base, "Ce créneau n'est plus disponible. Veuillez en sélectionner un autre.")
    end

    RdvPlan.transaction do
      # TODO: vérifier le niveau de notification de la participation
      rdv = Rdv.create(
        motif:, organisation:, lieu:, starts_at:,
        ends_at: starts_at + (duration_in_minutes || motif.default_duration_in_min).minutes,
        agents: [creneau.agent],
        users: [user],
        created_by: author
      )

      if rdv.persisted?
        update(rdv: rdv)
        Notifiers::RdvCreated.perform_with(rdv, inviting_agent)
      end
    end

    rdv
  end

  private

  def set_restricted_authentication_token
    # On reprend la même logique que CustomDeviseTokenGenerator
    self.restricted_auth_token = SecureRandom.send(:choose, [*"A".."Z", *"0".."9"], 8) until restricted_auth_token && Participation.where(restricted_auth_token:).none?
  end
end
