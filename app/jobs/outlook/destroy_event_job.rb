# frozen_string_literal: true

module Outlook
  class DestroyEventJob < ApplicationJob
    queue_as :outlook_sync

    def perform(outlook_id, agent)
      Outlook::Event.new(outlook_id: outlook_id, agent: agent).destroy

      agents_rdv = AgentsRdv.find_by(outlook_id: outlook_id)

      agents_rdv&.update!(outlook_id: nil, skip_outlook_update: true)
    end
  end
end
