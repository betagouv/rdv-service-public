module Caldav
  class ExportRdvToCaldavJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      perform_limit: 1,
      key: -> { "Caldav::ExportRdvToCaldavJob-#{arguments.first}" }
    )

    def perform(agents_rdv_id, agent_id, caldav_event_url: nil)
      @agents_rdv_id = agents_rdv_id
      @agent_id = agent_id
      return unless agent&.caldav_configured?

      Sentry.set_user({ id: agent.id, role: "Agent", email: agent.email })

      if agents_rdv
        if agents_rdv.caldav_url
          update_event
        else
          create_event
        end
      elsif caldav_event_url
        delete_event(caldav_event_url)
      end
    end

    private

    def create_event
      payload = agents_rdv.rdv.payload(action: :create, recipient: agents_rdv.agent, sensitive_data: agent.caldav_include_sensitive_data)
      ics = IcalFormatters::Ics.from_payload(payload).to_ical
      identifier = "agents_rdv-#{agents_rdv.id}.ics"
      event = agent.caldav_client.events.create(agent.caldav_agenda_url, identifier, ics)
      # Le provider Caldav n’utilise pas forcément l’identifiant qu’on lui donne pour créer l’event
      # on stocke donc l’url complète de l’event créé pour être sûr de pouvoir le retrouver.
      # On utilise update_columns pour éviter de déclencher des callbacks
      agents_rdv.update_columns(caldav_url: event.url) # rubocop:disable Rails/SkipsModelValidations
    end

    def update_event
      payload = agents_rdv.rdv.payload(action: :update, recipient: agents_rdv.agent, sensitive_data: agent.caldav_include_sensitive_data)
      ics = IcalFormatters::Ics.from_payload(payload).to_ical
      agent.caldav_client.events.update(agents_rdv.caldav_url, ics)
    end

    def delete_event(caldav_event_url)
      agent.caldav_client.events.delete(caldav_event_url)
    rescue Calendav::RequestError => e
      if e.response.status.code == 404
        # L'événement externe à supprimer est introuvable, pas la peine de retry
        Rails.logger.info("Got a 404 calling DELETE on #{caldav_event_url}")
      else
        raise
      end
    end

    def agent
      @agent ||= Agent.find_by_id(@agent_id)
    end

    def agents_rdv
      @agents_rdv ||= AgentsRdv.find_by_id(@agents_rdv_id)
    end
  end
end
