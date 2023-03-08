# frozen_string_literal: true

module Outlook
  class CreateEventJob < ApplicationJob
    queue_as :outlook_sync

    def perform(agents_rdv)
      outlook_event_id = Outlook::Event.new(agents_rdv: agents_rdv).create

      agents_rdv.update_columns(outlook_id: outlook_event_id) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
