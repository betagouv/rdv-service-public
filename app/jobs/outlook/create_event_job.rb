# frozen_string_literal: true

module Outlook
  class CreateEventJob < ApplicationJob
    def perform(agents_rdv)
      outlook_event = agents_rdv.create_outlook_event
      agents_rdv.update(outlook_id: outlook_event["id"], skip_outlook_update: true)
    end
  end
end
