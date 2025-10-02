module Caldav
  class SyncEventJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      perform_limit: 1,
      key: -> { "Caldav::SyncEventJob-#{arguments.first}" }
    )

    def perform(agents_rdv_id, agent_id, caldav_event_url: nil)
      @agents_rdv_id = agents_rdv_id
      @agent_id = agent_id

      return unless agent

      Sentry.set_user({ id: agent.id, role: "Agent", email: agent.email })

      return unless agent.caldav_configured?

      if caldav_event_url.present?
        if agents_rdv
          ics = IcalFormatters::Ics.from_payload(agents_rdv.rdv.payload(:update, agents_rdv.agent)).to_ical
          agent.caldav_client.events.update(caldav_event_url, ics)
        else
          agent.caldav_client.events.delete(caldav_event_url)
        end
      else
        ics = IcalFormatters::Ics.from_payload(agents_rdv.rdv.payload(:create, agents_rdv.agent)).to_ical
        identifier = "agents_rdv-#{agents_rdv.id}.ics"
        event = agent.caldav_client.events.create(agent.caldav_agenda_url, identifier, ics)
        # Le provider Caldav n’utilise pas forcément l’identifiant qu’on lui donne pour créer l’event
        # on stocke donc l’url complète de l’event créé pour être sûr de pouvoir le retrouver.
        agents_rdv.update!(caldav_url: event.url)
      end
    end

    private

    def agent
      @agent ||= Agent.find_by_id(@agent_id)
    end

    def agents_rdv
      @agents_rdv ||= AgentsRdv.find_by_id(@agents_rdv_id)
    end
  end
end
