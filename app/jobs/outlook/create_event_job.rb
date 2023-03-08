# frozen_string_literal: true

module Outlook
  class CreateEventJob < ApplicationJob
    queue_as :outlook_sync

    def perform(agents_rdv)
      client = Outlook::ApiClient.new(agents_rdv.agent)

      outlook_event_id = client.create_event!(agents_rdv.serialize_for_outlook_api)

      # On évite de lancer les callbacks en utilisant #updated_columns
      agents_rdv.update_columns(outlook_id: outlook_event_id) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
