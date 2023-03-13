# frozen_string_literal: true

module Outlook
  class MassCreateEventJob < ApplicationJob
    queue_as :outlook_sync

    def perform(agent)
      agent.agents_rdvs.future.find_each do |agents_rdv|
        Outlook::SyncEventJob.perform_later_for(agents_rdv)
      end
    end
  end
end
