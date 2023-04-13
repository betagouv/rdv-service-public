# frozen_string_literal: true

module Outlook
  class SyncEventJob < ApplicationJob
    queue_as :outlook_sync

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

    private

    def agents_rdv
      @agents_rdv ||= AgentsRdv.find_by_id(@agents_rdv_id)
    end

    def event_should_be_in_outlook?
      agents_rdv.present? && rdv.present? && !rdv.cancelled? && !rdv.soft_deleted?
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

      # On utilise #update_columns parce que les validations AR échouent si le rdv est soft-deleted
      # Ça permet aussi d'éviter de lancer les callbacks, dont notamment celui qui amène à l'exécution de ce job
      agents_rdv&.update_columns(outlook_id: nil) # rubocop:disable Rails/SkipsModelValidations
    end

    delegate :rdv, to: :agents_rdv

    def api_client
      @api_client ||= Outlook::ApiClient.new(@agent)
    end
  end
end
