module Caldav
  class MassDestroyEventJob < ApplicationJob
    queue_as :latency_5m
    include ExtendedRetryStrategyConcern

    def perform(agent)
      Sentry.set_user({ id: agent.id, role: "Agent", email: agent.email })

      @agent = agent

      return unless agent.caldav_configured?

      agent.agents_rdvs.where.not(caldav_url: nil).each do |agents_rdv|
        begin
          caldav_client.events.delete(agents_rdv.caldav_url)
        rescue Calendav::RequestError => e
          # On ignore les erreurs 404 (event déjà supprimé côté Caldav)
          raise unless e.message == "404 Not Found"
        end

        # TODO: manage 404 errors

        # On utilise #update_columns pour éviter de lancer les callbacks, dont notamment celui qui amène à l'exécution de ce job
        agents_rdv.update_columns(caldav_url: nil) # rubocop:disable Rails/SkipsModelValidations
      end

      agent.update!(caldav_username: nil, caldav_password: nil, caldav_agenda_url: nil, caldadv_disconnect_in_progress: false)
    end

    private

    def caldav_client
      @caldav_client ||= Calendav::Client.new(
        Calendav::Credentials::Standard.new(
          host: @agent.caldav_agenda_url,
          username: @agent.caldav_username,
          password: @agent.caldav_password,
          authentication: :basic_auth
        )
      )
    end
  end
end
