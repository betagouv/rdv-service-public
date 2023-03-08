# frozen_string_literal: true

module Outlook
  class EventSerializerAndListener
    def serialize
      {
        subject: rdv.object,
        body: {
          contentType: "HTML",
          content: event_description,
        },
        start: {
          dateTime: starts_at.iso8601,
          timeZone: Time.zone_default.tzinfo.identifier,
        },
        end: {
          dateTime: ends_at.iso8601,
          timeZone: Time.zone_default.tzinfo.identifier,
        },
        location: {
          displayName: rdv.address_without_personal_information,
        },
        attendees: [],
        # Le transactionId rend la création d'events idempotente.
        # On a parfois observé des appels à l'api de création qui renvoyaient un statut d'erreurs, mais qui
        # créent quand même un event. Le transactionId évite de créer des doublons dans ce cas.
        # voir https://learn.microsoft.com/en-us/graph/api/resources/event?view=graph-rest-1.0#properties
        transactionId: "agents_rdv-#{agents_rdv.id}",
      }
    end

    def self.set_callbacks!
      # On ajoute les callbacks à toutes les classes qui sont utilisées dans la méthode #serialize,
      # puisque si un de ces objet est modifié, il faut envoyer une mise à jour dans outlook.

      # Les before_commit permettent de marquer tous les agents_rdvs qui ont besoin d'être synchronisés dans outlook
      # Les after_commit permet d'enqueuer les jobs
      # Le découpage en deux temps permet d'envoyer un seul job si plusieurs callbacks sont appelés

      AgentsRdv
        .before_commit { |agents_rdv| mark_for_sync([agents_rdv]) }
      Rdv
        .before_commit { |rdv|        mark_for_sync(rdv.agents_rdvs) }
      RdvsUser
        .before_commit { |rdvs_user|  mark_for_sync(rdvs_user.rdv.agents_rdvs) }

      AgentsRdv
        .after_commit { |agents_rdv| enqueue_sync_for_marked_records([agents_rdv]) }
      Rdv
        .after_commit { |rdv|        enqueue_sync_for_marked_records(rdv.agents_rdv) }
      RdvsUser
        .after_commit { |rdvs_user|  enqueue_sync_for_marked_records(rdvs_user.rdv.agents_rdv) }
    end

    def self.mark_for_sync(agents_rdvs)
      agents_rdvs.select(&:agent_connected_to_outlook).each do |agents_rdv|
        agents_rdv.assign_attributes(needs_sync_to_outlook: true)
      end
    end

    def self.enqueue_sync_for_marked_records(agents_rdvs)
      agents_rdvs.select(&:needs_sync_to_outlook).each do |agents_rdv|
        EnqueueSyncToOutlook.run(agents_rdv)
        agents_rdv.assign_attributes(needs_sync_to_outlook: false)
      end
    end
  end

  def initialize(agents_rdv)
    @agents_rdv = agents_rdv
  end

  private

  delegate :rdv, :id, :users, to: :agents_rdv, allow_nil: true
  delegate :starts_at, :ends_at, to: :rdv

  def event_description
    url_helpers = Rails.application.routes.url_helpers

    show_link = url_helpers.admin_organisation_rdv_url(rdv.organisation, rdv.id, host: agent.dns_domain_name)
    edit_link = url_helpers.edit_admin_organisation_rdv_url(rdv.organisation, rdv.id, host: agent.dns_domain_name)

    participants_list = rdv.rdvs_users.not_cancelled.map do |rdv_user|
      "<li>#{rdv_user.user.full_name}</li>"
    end.join

    <<~HTML
      Participants:
      <ul>#{participants_list}</ul>
      <br />

      Plus d'infos sur <a href="#{show_link}">#{agent.domain_name}</a>:
      <br />

      Attention: ne modifiez pas cet évènement directement dans Outlook, car il ne sera pas mis à jour sur #{agent.domain_name}.
      Pour modifier ce rendez-vous, allez sur <a href="#{edit_link}">#{agent.domain_name}</a>
    HTML
  end
end
