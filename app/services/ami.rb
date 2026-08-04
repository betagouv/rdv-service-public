# Ce service est le point d'entrée principal pour l'intégration avec AMI
class Ami
  def self.enabled?
    ENV["AMI_ENABLED"] == "true"
  end

  def initialize(participation)
    @participation = participation
  end

  # Crée l'event dans AMI quand l'usager décide d'activer les notifications AMI pour ce rendez-vous
  def create_event
    send_event(
      content_body: "Vous avez pris rendez-vous à #{I18n.l(rdv.starts_at, format: :short_sms)}.", # Ce champs est visible pour Apple/Google
      content_private_body: "Vous avez rendez vous à #{I18n.l(rdv.starts_at, format: :short_sms)} à #{rdv.address}",
      item_generic_status: "new",
      item_status_label: "À venir",
      try_push: false # On crée cet event après que l'usager décide d'activer les notifications, donc pas besoin d'activer la notification
    )
  end

  def send_event_update_notification
    send_event(
      content_body: "Votre rendez-vous a été modifié", # Ce champs est visible pour Apple/Google
      content_private_body: "Vous avez maintenant rendez vous à #{I18n.l(rdv.starts_at, format: :short_sms)} à #{rdv.address}",
      item_generic_status: "wip",
      item_status_label: "À venir",
      try_push: true
    )
  end

  # On ajoutera cet appel dans Notifiers::RdvUpcomingReminder
  def send_reminder
    # Cette notif devrait peut-être être juste une notif toute seule, pas dans le cadre d'une démarche.
    send_event(
      content_body: "Vous avez rendez-vous à #{I18n.l(rdv.starts_at, format: :short_sms)}.", # Ce champs est visible pour Apple/Google
      item_generic_status: "wip",
      item_status_label: "À venir",
      try_push: true
    )
  end

  def close_event
    # Pour bien gérer les annulations, il faudra mettre des content_body différents
    send_event(
      content_body: "Vous aviez rendez-vous à #{I18n.l(rdv.starts_at, format: :short_sms)}.", # Ce champs est visible pour Apple/Google
      item_generic_status: "closed",
      item_status_label: "Terminé",
      try_push: false
    )
  end

  # On garde cette méthode publique pour faciliter les tests en console.
  def send_event(payload)
    # Quand on fera les vrais appels il faudra mettre tous les jobs en perform_later avec la bonne queue
    Ami::SendEventJob.new.perform(default_payload.merge(payload))
  end

  private

  delegate :rdv, to: :@participation

  def default_payload
    {
      content_title: "Rendez-vous en France Service",
      recipient_fc_hash: @participation.user.ami_france_connect_hash,
      event_date: Time.zone.now,
      content_icon: "fr-icon-calendar-event-line",
      item_type: "RDV",
      item_id: @participation.rdv_id,
      content_link: Rails.application.routes.url_helpers.rdv_short_from_token_url(@participation.restricted_auth_token, host: domain_host),
      valid_until: @participation.rdv.starts_at.iso8601,
    }
  end

  def domain_host
    @participation.rdv.domain.host_name
  end
end
