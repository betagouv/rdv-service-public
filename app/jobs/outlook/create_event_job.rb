# frozen_string_literal: true

module Outlook
  class CreateEventJob < ApplicationJob
    def perform(agents_rdv)
      outlook_event = Outlook::Event.new(agents_rdv: agents_rdv).create
      agents_rdv.update(outlook_id: outlook_event["id"], skip_outlook_update: true)
    end
  end
end
