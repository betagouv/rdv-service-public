module Caldav
  class MassDestroyEventJob < ApplicationJob
    queue_as :latency_5m
    include ExtendedRetryStrategyConcern

    def perform(agent)
      Sentry.set_user({ id: agent.id, role: "Agent", email: agent.email })

      return unless agent.caldav_configured?

      agent.agents_rdvs.where.not(caldav_url: nil).each do |agents_rdv|
        begin
          agent.caldav_client.events.delete(agents_rdv.caldav_url)
        rescue Calendav::RequestError => e
          # On ignore les erreurs 404 (event déjà supprimé côté Caldav)
          raise unless e.message == "404 Not Found"
        end

        # On utilise #update_columns pour éviter de lancer les callbacks, dont notamment celui qui amène à l'exécution de ce job
        agents_rdv.update_columns(caldav_url: nil) # rubocop:disable Rails/SkipsModelValidations
      end

      agent.update!(caldav_username: nil, caldav_password: nil, caldav_agenda_url: nil, caldav_disconnect_in_progress: false)
    end
  end
end
