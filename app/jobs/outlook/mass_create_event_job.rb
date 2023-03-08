# frozen_string_literal: true

module Outlook
  class MassCreateEventJob < ApplicationJob
    queue_as :outlook_sync

    def perform(agent)
      agent.agents_rdvs.future.each do |agents_rdv|
        EnqueueSyncToOutlook.run(agents_rdv)
      end
    end
  end
end
