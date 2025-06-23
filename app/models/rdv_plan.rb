class RdvPlan < ApplicationRecord
  belongs_to :planning_agent, class_name: "Agent"
  belongs_to :user

  belongs_to :rdv_agent, class_name: "Agent", optional: true
  belongs_to :motif, optional: true
  belongs_to :lieu, optional: true
  belongs_to :rdv, optional: true
  # Le `optional: true` sur les oauth_application est un peu anticipé : on pourra avoir ce cas quand des
  # rdv_plans seront créés en natif depuis l'application, probablement pour enregistrer un brouillon de rdv
  # TODO: il faudrait mettre à jour la spec swagger pour utiliser de l'oauth pour pouvoir enlever le `optional: true`
  belongs_to :oauth_application, class_name: "Doorkeeper::Application", optional: true

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
    update_user_before_creating_rdv(user_attributes:)

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

  def update_user_before_creating_rdv(user_attributes:)
    if user.email
      if user_attributes[:notification_email]&.downcase == user.email || user_attributes[:notification_email].blank?
        # L'email est le même, mais on veut quand même changer le numéro de téléphone
        user.update!(user_attributes)
      elsif user.encrypted_password.present? # On essaye de changer l'email de l'usager
        # Dans ce cas l'usager a un compte Devise qui lui sert à se connecter
        # A terme, on voudrait ne pas avoir à faire cette vérification, et que la présence d'une valeur dans la colonne email
        # suffise à déterminer que l'usager a un compte Devise
        raise "L'email de cet usager ne peut pas être modifié"
      else
        # Pour mettre à jour l'email sans renvoyer de mail de confirmation
        user.skip_confirmation_notification!
        user.skip_reconfirmation!

        # Le notification_email peut remplacer l'email sans risque, puisque l'usager n'a pas de compte Devise
        user.assign_attributes(email: nil)
        user.update!(user_attributes)
      end
    else
      user.update!(user_attributes)
    end
  end

  def return_url_is_authorized
    return if return_url.blank?

    return_uri = URI.parse(return_url)

    unless return_uri.scheme&.in?(%w[http https])
      errors.add(:return_url, "Doit utiliser http ou https")
    end

    authorized_domain_names = oauth_application.redirect_uri.split("\n").map do |uri|
      URI.parse(uri).host
    end
    unless return_uri.host&.in?(authorized_domain_names)
      errors.add(:return_url, "n'est pas un nom de domaine autorisé")
    end
  end
end
