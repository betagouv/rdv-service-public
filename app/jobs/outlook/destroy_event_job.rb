# frozen_string_literal: true

module Outlook
  class DestroyEventJob < ApplicationJob
    def perform(agents_rdv)
      outlook_event = agents_rdv.destroy_outlook_event
      agents_rdv.update(outlook_id: nil, skip_outlook_update: true) unless outlook_event["error"].present?
    end
  end
end
