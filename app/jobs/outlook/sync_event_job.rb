# frozen_string_literal: true

module Outlook
  class SyncEventJob < ApplicationJob
    queue_as :outlook_sync

    def perform(agents_rdv, outlook_id)
      @agents_rdv = agents_rdv
      @outlook_id = outlook_id || agents_rdv.outlook_id

      return unless @agents_rdv.agent_connected_to_outlook?

      if event_should_be_in_outlook?
        create_or_update_event
      elsif @agents_rdv.outlook_id
        delete_event
      end
    end

    private

    def event_should_be_in_outlook?
      rdv_is_not_cancelled_or_deleted? && !@agents_rdv.destroyed?
    end

    def rdv_is_not_cancelled_or_deleted?
      !rdv.cancelled? && !rdv.soft_deleted? && !rdv.destroyed?
    end

    def create_or_update_event
      if @agents_rdv.outlook_id
        api_client.update_event!(@agents_rdv.outlook_id, @agents_rdv.serialize_for_outlook_api)
      else
        outlook_event_id = api_client.create_event!(@agents_rdv.serialize_for_outlook_api)

        # On évite de lancer les callbacks en utilisant #updated_columns, notamment celui qui est à
        # l'origine de l'exécution de ce job
        @agents_rdv.update_columns(outlook_id: outlook_event_id) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    def rdv
      @agents_rdv.rdv
    end

    def api_client
      @api_client ||= Outlook::ApiClient.new(@agents_rdv.agent)
    end
  end
end
