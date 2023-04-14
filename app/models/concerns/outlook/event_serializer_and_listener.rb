# frozen_string_literal: true

# Ce concern a la responsabilité de faire la sérialisation qui permet de générer le json envoyé
# à Outlook pour représenter un AgentsRdv sous la forme d'un event.
# La connaissance du graphe d'objet qui sert à faire cette sérialisation permet de savoir sur quelles
# classes activerecord il faut ajouter des callbacks pour surveiller leur changement.
#
# Plutôt que de disséminer ces callbacks dans les models activerecords, leur définitions sont regroupées ici.
# C'est inhabituel, mais ça a plusieurs avantages :
# - la définition des callbacks est explicite, on sait exactement à quoi ils servent, et ils sont indépendants
#   de callbacks très génériques du genre `belongs_to :rdv, touch: true`.
# - la liste des classes sur lesquels on ajoute des callbacks est groupée avec la raison d'être de ces callbacks.
#   Par exemple, si on change la sérialisation pour ajouter un autre objet dans la description, on espère que ça sera
#   clair qu'il faut aussi ajouter cet object dans la liste des callbacks
# - Les modèles activerecord n'ont pas besoin de connaitre le fonctionnement de la synchro Outlook.
#   La dépendance est dans l'autre sens : c'est la synchro Outlook qui connait les modèles AR (puisqu'elle
#   les traduit en events outlook)
module Outlook
  module EventSerializerAndListener
    extend ActiveSupport::Concern

    included do
      attr_accessor :needs_sync_to_outlook

      delegate :connected_to_outlook?, to: :agent, prefix: true

      # On ajoute les callbacks à toutes les classes qui sont utilisées dans la méthode #serialize_for_outlook_api,
      # puisque si un de ces objet est modifié, il faut envoyer une mise à jour dans outlook.
      #
      # On ajoute l'attribut :needs_sync_to_outlook et des callbacks en deux temps pour enqueuer exactement un job
      # par transaction, peu importe le nombre d'objets changés.
      # Par exemple, si on a une transaction qui crée un AgentsRdv, un Rdv et un RdvsUser (typiquement à la création d'un rdv),
      # le système utilisé ici enqueuera un seul job.
      #
      # Par ailleurs, si un seul des trois objets est modifié (par exemple un RdvUser qui change d'état), on aura toujours
      # un job qui sera envoyé.

      # before_commit: On parcourt le graphe des objets pour marquer tous les agents_rdvs qui ont besoin
      # d'être synchronisés dans Outlook
      AgentsRdv.before_commit do |agents_rdv|
        Outlook::EventSerializerAndListener.mark_for_sync([agents_rdv])
      end
      Rdv.before_commit do |rdv|
        Outlook::EventSerializerAndListener.mark_for_sync(rdv.agents_rdvs)
      end
      RdvsUser.before_commit do |rdvs_user|
        Outlook::EventSerializerAndListener.mark_for_sync(rdvs_user.rdv.agents_rdvs)
      end

      # after_commit: On trouve tous les agents_rdvs qui ont été marqués, on enqueue les jobs, et on
      # enlève le marquage pour enqueuer un seul job par transaction
      AgentsRdv.after_commit do |agents_rdv|
        Outlook::EventSerializerAndListener.enqueue_sync_for_marked_records([agents_rdv])
      end
      Rdv.after_commit do |rdv|
        Outlook::EventSerializerAndListener.enqueue_sync_for_marked_records(rdv.agents_rdvs)
      end
      RdvsUser.after_commit do |rdvs_user|
        Outlook::EventSerializerAndListener.enqueue_sync_for_marked_records(rdvs_user.rdv.agents_rdvs)
      end
    end

    # Les motifs et les lieux apparaissent dans la description de l'event, mais on a fait le choix métier
    # de ne pas faire une mise à jour de tous les events si le motif ou le lieu est changé. (ça peut être réévalué
    # en fonction des retours utilisateurs)
    def serialize_for_outlook_api
      {
        subject: rdv.object,
        body: {
          contentType: "HTML",
          content: event_description,
        },
        start: {
          dateTime: rdv.starts_at.iso8601,
          timeZone: Time.zone_default.tzinfo.identifier,
        },
        end: {
          dateTime: rdv.ends_at.iso8601,
          timeZone: Time.zone_default.tzinfo.identifier,
        },
        location: {
          displayName: rdv.address_without_personal_information,
        },
        attendees: [],
        transactionId: "agents_rdv-#{id}", # voir https://learn.microsoft.com/en-us/graph/api/resources/event?view=graph-rest-1.0#properties
      }
    end

    def self.mark_for_sync(agents_rdvs)
      agents_rdvs.select(&:agent_connected_to_outlook?).each do |agents_rdv|
        agents_rdv.assign_attributes(needs_sync_to_outlook: true)
      end
    end

    def self.enqueue_sync_for_marked_records(agents_rdvs)
      agents_rdvs.select(&:needs_sync_to_outlook).each do |agents_rdv|
        Outlook::SyncEventJob.perform_later_for(agents_rdv)
        agents_rdv.assign_attributes(needs_sync_to_outlook: false)
      end
    end

    private

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
end
