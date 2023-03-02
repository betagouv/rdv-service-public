# frozen_string_literal: true

module Outlook
  class DestroyEventJob < ApplicationJob
    queue_as :outlook_sync

    def perform(outlook_id, agent)
      Outlook::Event.new(outlook_id: outlook_id, agent: agent).destroy

      agents_rdv = AgentsRdv.find_by(outlook_id: outlook_id)

      # We use #update_columns because the validation will fail because the rdv can be soft-deleted
      # It also allows skipping the outlook_update callback
      agents_rdv&.update_columns(outlook_id: nil) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
