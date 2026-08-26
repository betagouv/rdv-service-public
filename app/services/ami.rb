# Ce service est le point d'entrée principal pour l'intégration avec AMI
# Documentation technique d'AMI : https://pad.numerique.gouv.fr/s/9L5vb77qA
# Les identifiants pour tester en local sont disponibles sur Vaulwarden
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
      # Vu qu'il n'y a pas de notification pour l'évènement, on peut mettre le motif dans le content_body sans qu'il ne soit envoyé à Apple/Google
      content_body: "Vous avez rendez vous #{I18n.l(rdv.starts_at, format: :short_sms)} au #{rdv.address} pour #{rdv.motif.name}",
      item_generic_status: "new",
      item_status_label: "À venir",
      try_push: false # On crée cet event après que l'usager décide d'activer les notifications, donc pas besoin d'activer la notification
    )
  end

  def send_event_update_notification
    send_event(
      content_body: "Votre rendez-vous a été modifié.", # Ce champs est visible pour Apple/Google
      content_private_body: "Vous avez maintenant rendez vous #{I18n.l(rdv.starts_at, format: :short_sms)} au #{rdv.address}",
      item_generic_status: "wip",
      item_status_label: "À venir",
      try_push: true
    )
  end

  # On ajoutera cet appel dans Notifiers::RdvUpcomingReminder
  def send_reminder
    # Cette notif devrait peut-être être juste une notif toute seule, pas dans le cadre d'une démarche.
    payload = {
      content_body: "Nous vous rappelons que vous avez rendez-vous #{I18n.l(rdv.starts_at, format: :short_sms)}.", # Ce champs est visible pour Apple/Google
      content_private_body: "Le rendez-vous aura lieu au #{rdv.address} pour #{rdv.motif.name}",
      item_generic_status: "wip",
      item_status_label: "À venir",
      try_push: true,
    }

    Ami::SendEventJob.set(queue: :latency_5m).perform_later(default_payload.merge(payload))
  end

  def close_event
    # Pour bien gérer les annulations, il faudra mettre des content_body différents
    send_event(
      content_body: "Votre rendez-vous est terminé.", # Ce champs est visible pour Apple/Google
      item_generic_status: "closed",
      item_status_label: "Terminé",
      try_push: false
    )
  end

  # TODO: ajouter une notification pour les annulations

  # On garde cette méthode publique pour faciliter les tests en console.
  def send_event(payload)
    Ami::SendEventJob.perform_later(default_payload.merge(payload))
  end

  private

  delegate :rdv, to: :@participation

  def default_payload
    {
      content_title: "Rendez-vous en France Service",
      recipient_fc_hash: AmiFranceConnectHash.find_by(user: @participation.user).fc_hash,
      event_date: Time.zone.now,
      content_icon: "fr-icon-calendar-event-line",
      item_type: "RDV",
      item_id: @participation.rdv.uuid, # Ce champs est affiché en tant que "référence dossier" dans l'interface d'AMI, il faudrait peut-être mettre autre chose
      content_link: Rails.application.routes.url_helpers.rdv_short_from_token_url(@participation.restricted_auth_token, host: domain_host).gsub("localhost", "localhost:3000"),
      valid_until: @participation.rdv.ends_at.iso8601,
      item_milestone_start_date: @participation.rdv.starts_at.iso8601,
      item_milestone_end_date: @participation.rdv.ends_at.iso8601,
    }
  end

  def domain_host
    @participation.rdv.domain.host_name
  end
end
