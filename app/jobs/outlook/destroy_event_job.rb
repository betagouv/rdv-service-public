# frozen_string_literal: true

module Outlook
  class DestroyEventJob < ApplicationJob
    def perform(agents_rdv)
      # Problème: quand destroy, plus de agents_rdv
      outlook_event = Outlook::Event.new(agents_rdv: agents_rdv).destroy
      agents_rdv.update(outlook_id: nil, skip_outlook_update: true) if outlook_event["error"].blank?
    rescue ActiveJob::DeserializationError
    end
  end
end
