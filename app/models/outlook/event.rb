# frozen_string_literal: true

# Responsable de la sérialisation d'un event outlook à partir de nos données,
# et donc aussi d'ajouter les callbacks qui feront ces mises à jour
module Outlook
  class Event
    attr_reader :agents_rdv, :outlook_id, :agent

    def self.set_callbacks!
      AgentRdv.attr_accessor :needs_sync_to_outlook

      # On ajoute les callbacks à toutes les classes qui sont utilisées pour générer un event,
      # puisque si un de ces objet est modifié, il faut envoyer une mise à jour dans outlook.
      Rdv.after_save do |rdv|
        rdv.agents_rdvs.joins(:agent).merge(agent: Agent.connected_to_outlook).each do |agents_rdv|
          agents_rdv.assign_attributes(needs_sync_to_outlook: true)
        end
      end

      AgentsRdv.after_commit do |agents_rdv|
        if agents_rdv.needs_sync_to_outlook
          OutlookEvent.new(agents_rdv: agents_rdv).sync_to_outlook
        end
      end
    end

    def initialize(outlook_id: nil, agents_rdv: nil, agent: nil)
      @agents_rdv = agents_rdv
      @outlook_id = @agents_rdv&.outlook_id || outlook_id
      @agent = @agents_rdv&.agent || agent
    end

    def create
      api_client.create_event(payload)
    end

    def update
      api_client.update_event(outlook_id, payload)
    end

    def destroy
      api_client.delete_event(outlook_id)
    end

    private

    def api_client
      @api_client ||= Outlook::ApiClient.new(@agent)
    end

    delegate :rdv, :id, :users, to: :agents_rdv, allow_nil: true
    delegate :microsoft_graph_token, :connected_to_outlook?, to: :agent, prefix: true
    delegate :object, :starts_at, :ends_at, :address_without_personal_information, to: :rdv

    def payload
      {
        subject: object,
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
          displayName: address_without_personal_information,
        },
        attendees: [],
        # Le transactionId rend la création d'events idempotente.
        # On a parfois observé des appels à l'api de création qui renvoyaient un statut d'erreurs, mais qui
        # créent quand même un event. Le transactionId évite de créer des doublons dans ce cas.
        # voir https://learn.microsoft.com/en-us/graph/api/resources/event?view=graph-rest-1.0#properties
        transactionId: "agents_rdv-#{agents_rdv.id}",
      }
    end

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
