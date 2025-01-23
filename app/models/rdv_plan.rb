class RdvPlan < ApplicationRecord
  belongs_to :planning_agent, class_name: "Agent"
  belongs_to :user

  belongs_to :rdv_agent, class_name: "Agent", optional: true
  belongs_to :motif, optional: true
  belongs_to :lieu, optional: true
  belongs_to :rdv, optional: true

  delegate :organisation, to: :motif

  validate :return_url_is_authorized

  # TODO: mettre en commun avec les motifs et ajouter une validation de synchro
  enum :location_type, { public_office: "public_office", phone: "phone", home: "home", visio: "visio" }

  def modalite
    if location_type == "public_office"
      "#{location_type}-#{lieu&.id}"
    else
      location_type
    end
  end

  def modalite=(modalite)
    self.location_type, self.lieu_id = modalite.split("-")
  end

  def create_rdv(user_attributes:, participation_attributes:)
    user.skip_reconfirmation! if user.encrypted_password.blank? # Pour mettre à jour l'email sans renvoyer de mail de confirmation
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

  private

  def return_url_is_authorized
    return if return_url.blank?

    uri = URI.parse(return_url)

    unless uri.scheme&.in?(%w[http https])
      errors.add(:return_url, "Doit utiliser http ou https")
    end
    unless uri.host&.end_with?(".gouv.fr")
      errors.add(:return_url, "N'est pas un nom de domaine autorisé")
    end
  end
end
