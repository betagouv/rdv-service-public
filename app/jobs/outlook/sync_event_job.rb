module Outlook
  class SyncEventJob < ApplicationJob
    queue_as :outlook_sync

    include GoodJob::ActiveJobExtensions::Concurrency
    good_job_control_concurrency_with(
      perform_limit: 1,
      # Pour limiter les risque d'une race condition de deux création d'event en même temps
      # on limite les exécutions concurrentes à un job pour un agents_rdv.
      key: -> { "Outlook::SyncEventJob-#{arguments.first}" }
    )

    def self.perform_later_for(agents_rdv)
      if agents_rdv.outlook_id.nil? && !agents_rdv.destroyed?
        agents_rdv.update_columns(outlook_create_in_progress: true) # rubocop:disable Rails/SkipsModelValidations
      end
      # En cas de suppression du agents_rdv, on ne pourra pas le désérialiser au moment de l'exécution du job.
      # On aura donc besoin du outlook_id et de l'agent pour supprimer l'event dans Outlook
      perform_later(agents_rdv.id, agents_rdv.outlook_id, agents_rdv.agent)
    end

    def perform(agents_rdv_id, outlook_id, agent)
      @agents_rdv_id = agents_rdv_id
      @outlook_id = outlook_id
      @agent = agent

      return unless agent.connected_to_outlook?

      if event_should_be_in_outlook?
        create_or_update_event
      elsif @outlook_id
        delete_event
      end
    end

    def capture_sentry_warning_for_retry?(exception)
      # Cette erreur se produit parfois à la première exécution, puis le job passe au retry.
      if exception.is_a?(Outlook::ApiClient::RefreshTokenError)
        executions > 4
      else
        super
      end
    end

    private

    def agents_rdv
      @agents_rdv ||= AgentsRdv.find_by_id(@agents_rdv_id)
    end

    def event_should_be_in_outlook?
      agents_rdv.present? && rdv.present? && !rdv.cancelled?
    end

    def create_or_update_event
      if agents_rdv.outlook_id
        api_client.update_event!(agents_rdv.outlook_id, agents_rdv.serialize_for_outlook_api)
      else
        return unless agents_rdv.outlook_create_in_progress

        agents_rdv.update_columns(outlook_create_in_progress: false) # rubocop:disable Rails/SkipsModelValidations

        outlook_event_id = api_client.create_event!(agents_rdv.serialize_for_outlook_api)

        # On évite de lancer les callbacks en utilisant #update_columns, notamment celui qui est à
        # l'origine de l'exécution de ce job
        agents_rdv.update_columns(outlook_id: outlook_event_id) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    def delete_event
      api_client.delete_event!(@outlook_id)

      agents_rdv = AgentsRdv.find_by(outlook_id: @outlook_id)

      # On utilise #update_columns pour éviter de lancer les callbacks, dont notamment celui qui amène à l'exécution de ce job
      agents_rdv&.update_columns(outlook_id: nil) # rubocop:disable Rails/SkipsModelValidations
    end

    delegate :rdv, to: :agents_rdv

    def api_client
      @api_client ||= Outlook::ApiClient.new(@agent)
    end
  end
end
