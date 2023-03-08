# frozen_string_literal: true

module Outlook
  class CreateOrUpdateEventJob < ApplicationJob
    queue_as :outlook_sync

    def perform(agents_rdv)
      client = Outlook::ApiClient.new(agents_rdv.agent)

      if agents_rdv.outlook_id
        client.update_event!(agents_rdv.outlook_id, agents_rdv.serialize_for_outlook_api)
      else
        outlook_event_id = client.create_event!(agents_rdv.serialize_for_outlook_api)

        # On évite de lancer les callbacks en utilisant #updated_columns, notamment celui qui est à
        # l'origine de l'exécution de ce job
        agents_rdv.update_columns(outlook_id: outlook_event_id) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end
end
