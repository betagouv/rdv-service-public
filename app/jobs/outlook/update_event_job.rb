# frozen_string_literal: true

module Outlook
  class UpdateEventJob < ApplicationJob
    queue_as :outlook_sync

    def perform(agents_rdv)
      client = Outlook::ApiClient.new(agents_rdv.agent)

      client.update_event!(agents_rdv.outlook_id, agents_rdv.serialize_for_outlook_api)
    end
  end
end
