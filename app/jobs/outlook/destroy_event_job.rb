# frozen_string_literal: true

module Outlook
  class DestroyEventJob < ApplicationJob
    def perform(agents_rdv)
      outlook_event = agents_rdv.destroy_outlook_event
      agents_rdv.update(outlook_id: nil, skip_outlook_update: true) if outlook_event["error"].blank?
    end
  end
end
