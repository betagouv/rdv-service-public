module Outlook
  class MassDestroyEventJob < ApplicationJob
    queue_as :latency_5m
    include ExtendedRetryStrategyConcern

    def perform(agent)
      Sentry.set_user({ id: agent.id, role: "Agent", email: agent.email })

      client = Outlook::ApiClient.new(agent.outlook_config)

      agent.agents_rdvs.where.not(outlook_id: nil).each do |agents_rdv|
        client.delete_event!(agents_rdv.outlook_id)

        # On utilise #update_columns pour éviter de lancer les callbacks, dont notamment celui qui amène à l'exécution de ce job
        agents_rdv.update_columns(outlook_id: nil) # rubocop:disable Rails/SkipsModelValidations
      end

      agent.outlook_config.destroy!
    rescue Outlook::ApiClient::InvalidGrantError => e
      # Le refresh token est définitivement invalide : inutile de retenter, on désactive la synchro et on prévient l'agent.
      if agent.reload.outlook_config # On se sert de `outlook_config` comme sémaphore pour éviter que plusieurs jobs passent ici en même temps.
        agent.outlook_config.destroy!
        Agents::OutlookSyncMailer.with(agent: agent, error_description: e.error_description).sync_disabled.deliver_later
      end
    end
  end
end
