# frozen_string_literal: true

module Outlook
  class CreateEventJob < ApplicationJob
    queue_as :outlook_sync

    def perform(agents_rdv)
      client = Outlook::ApiClient.new(agents_rdv.agent)
      serializer = EventSerializerAndListener.new(agents_rdv)

      outlook_event_id = client.create_event(serializer.serialize)

      agents_rdv.update_columns(outlook_id: outlook_event_id) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
