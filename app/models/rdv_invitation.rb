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

  validate :user_can_be_notified
  validate :validate_phone_number_present_for_motif_by_phone
  validate :motif_is_supported

  def creneaux_search(starts_at)
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
      return
    end

    RdvPlan.transaction do
      # TODO: vérifier le niveau de notification de la participation
      # TODO: gérer les erreurs sur le rdv
      rdv = Rdv.create(
        motif:, organisation:, lieu:, starts_at:,
        ends_at: starts_at + motif.default_duration_in_min.minutes,
        agents: [creneau.agent],
        users: [user],
        created_by: user
      )

      if rdv.persisted?
        update(rdv: rdv)
        Notifiers::RdvCreated.perform_with(rdv, user)
      end
    end

    rdv
  end

  private

  def user_can_be_notified
    return if user.user_to_notify.email.present?

    errors.add(:base, "#{user.user_to_notify.full_name} n'a pas d'adresse email, et ne peut donc pas recevoir d'invitation.")
  end

  def motif_is_supported
    if motif.collectif?
      errors.add(:base, "Les invitations ne sont pas encore possible pour les motifs collectifs")
    end

    if motif.requires_ants_predemande_number?
      errors.add(:base, "Les invitations ne sont pas encore possible pour les motifs liés à France Titres")
    end
  end

  def validate_phone_number_present_for_motif_by_phone
    if motif.phone? && user.phone_number.blank?
      errors.add(:base, "Le motif est pas téléphone mais  le numéro de #{user.full_name} n'est pas renseigné.")
    end
  end

  def set_restricted_authentication_token
    # On reprend la même logique que CustomDeviseTokenGenerator
    self.token = SecureRandom.send(:choose, [*"A".."Z", *"0".."9"], 8) until token && self.class.where(token:).none?
  end
end
