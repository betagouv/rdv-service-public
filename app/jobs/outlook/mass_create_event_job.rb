# frozen_string_literal: true

module Outlook
  class MassCreateEventJob < ApplicationJob
    queue_as :outlook_sync

    def perform(agent)
      agent.agents_rdvs.includes(:rdv).where(rdv: { starts_at: 1.month.ago.. }).find_each do |agents_rdv|
        if agents_rdv.outlook_id.nil?
          agents_rdv.update_columns(outlook_create_in_progress: true) # rubocop:disable Rails/SkipsModelValidations
        end
        Outlook::SyncEventJob.perform_later_for(agents_rdv)
      end
    end
  end
end
