module Outlook
  class MassDestroyEventJob < ApplicationJob
    queue_as :latency_5m
    include ExtendedRetryStrategyConcern

    def perform(agent)
      Sentry.set_user({ id: agent.id, role: "Agent", email: agent.email })

      client = Outlook::ApiClient.new(agent)

      agent.agents_rdvs.where.not(outlook_id: nil).each do |agents_rdv|
        client.delete_event!(agents_rdv.outlook_id)

        # On utilise #update_columns pour éviter de lancer les callbacks, dont notamment celui qui amène à l'exécution de ce job
        agents_rdv.update_columns(outlook_id: nil) # rubocop:disable Rails/SkipsModelValidations
      end

      agent.update!(microsoft_graph_token: nil, refresh_microsoft_graph_token: nil, outlook_disconnect_in_progress: false)
    end
  end
end
