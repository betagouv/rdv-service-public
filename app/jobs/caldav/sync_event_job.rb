module Caldav
  class SyncEventJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      perform_limit: 1,
      key: -> { "Caldav::SyncEventJob-#{arguments.first}" }
    )

    def perform(agents_rdv_id)
      @agents_rdv_id = agents_rdv_id

      Sentry.set_user({ id: agents_rdv.agent.id, role: "Agent", email: agents_rdv.agent.email })

      return unless agents_rdv.agent.caldav_configured?

      if agents_rdv.caldav_url.present?
        ics = IcalFormatters::Ics.from_payload(agents_rdv.rdv.payload(:update, agents_rdv.agent)).to_ical
        caldav_client.events.update(agents_rdv.caldav_url, ics)
      else
        ics = IcalFormatters::Ics.from_payload(agents_rdv.rdv.payload(:create, agents_rdv.agent)).to_ical
        identifier = "agents_rdv-#{agents_rdv.id}.ics"
        event = caldav_client.events.create(agents_rdv.agent.caldav_agenda_url, identifier, ics)
        # Le provider Caldav n’utilise pas forcément l’identifiant qu’on lui donne pour créer l’event
        # on stocke donc l’url complète de l’event créé pour être sûr de pouvoir le retrouver.
        agents_rdv.update!(caldav_url: event.url)
      end
    end

    private

    def caldav_client
      @caldav_client ||= Calendav::Client.new(
        Calendav::Credentials::Standard.new(
          host: agents_rdv.agent.caldav_agenda_url,
          username: agents_rdv.agent.caldav_username,
          password: agents_rdv.agent.caldav_password,
          authentication: :basic_auth
        )
      )
    end

    def agents_rdv
      @agents_rdv ||= AgentsRdv.find_by_id(@agents_rdv_id)
    end
  end
end
