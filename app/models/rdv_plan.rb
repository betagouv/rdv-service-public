class RdvPlan < ApplicationRecord
  self.ignored_columns += ["location_type"]

  has_paper_trail(
    only: %i[planning_agent_id rdv_id user_id rdv_agent_id motif_id lieu_id starts_at duration_in_minutes return_url dossier_url]
  )

  belongs_to :planning_agent, class_name: "Agent"
  belongs_to :user

  belongs_to :rdv_agent, class_name: "Agent", optional: true
  belongs_to :motif, optional: true
  belongs_to :lieu, optional: true
  belongs_to :rdv, optional: true
  belongs_to :rdv_invitation, optional: true

  # Le `optional: true` sur les oauth_application est un peu anticipé : on pourra avoir ce cas quand des
  # rdv_plans seront créés en natif depuis l'application, probablement pour enregistrer un brouillon de rdv
  # TODO: il faudrait mettre à jour la spec swagger pour utiliser de l'oauth pour pouvoir enlever le `optional: true`
  belongs_to :oauth_application, class_name: "Doorkeeper::Application", optional: true

  delegate :organisation, to: :motif

  validate :return_url_is_authorized

  def create_rdv_or_send_invitation(user_attributes:, participation_attributes: nil, pro_connect_access_token: nil)
    user.update!(user_attributes)

    UserProfile.find_or_initialize_by(user_id: user.id, organisation_id: motif.organisation_id).save!

    if by_invitation?
      create_rdv_invitation(pro_connect_access_token)
    else
      create_rdv(participation_attributes:, pro_connect_access_token:)
    end
  end

  def build_invitation
    RdvInvitation.new(motif:, lieu:, user:, inviting_agent: planning_agent)
  end

  private

  def create_rdv(participation_attributes:, pro_connect_access_token:)
    rdv = Rdv.create(
      motif:, lieu:, starts_at:,
      agents: [rdv_agent],
      participations: [Participation.new(participation_attributes.merge(user_id: user.id))],
      organisation: organisation,
      created_by: planning_agent,
      ends_at: starts_at + (duration_in_minutes || motif.default_duration_in_min).minutes,
      visio_url_custom: visio_url_custom(pro_connect_access_token)
    )

    if rdv.persisted?
      update(rdv:)
      Notifiers::RdvCreated.perform_with(rdv, planning_agent)
    end

    rdv
  end

  def create_rdv_invitation(pro_connect_access_token)
    invitation = build_invitation
    invitation.visio_url_custom = visio_url_custom(pro_connect_access_token)
    if invitation.save
      update!(rdv_invitation_id: invitation.id)
      Users::RdvInvitationMailer.with(rdv_invitation: invitation).new_invitation.deliver_later
    end

    invitation
  end

  def visio_url_custom(pro_connect_access_token)
    return unless motif&.visio?
    return if ENV["VISIO_NUMERIQUE_DISABLED"]
    return if pro_connect_access_token.blank?

    VisioNumerique::CreateRoom.new(access_token: pro_connect_access_token).visio_url
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
