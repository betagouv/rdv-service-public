# frozen_string_literal: true

module Outlook
  class DestroyEventJob < ApplicationJob
    queue_as :outlook_sync

    def perform(outlook_id, agent)
      outlook_event = Outlook::Event.new(outlook_id: outlook_id, agent: agent).destroy

      if outlook_event["error"].blank?
        AgentsRdv.find_by(outlook_id: outlook_id)&.update(outlook_id: nil, skip_outlook_update: true)
      end
    end
  end
end
