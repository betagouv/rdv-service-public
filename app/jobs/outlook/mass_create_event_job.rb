# frozen_string_literal: true

module Outlook
  class MassCreateEventJob < ApplicationJob
    queue_as :outlook_sync

    def perform(agent)
      # TODO: fix bug: if rdv is cancelled, we don't want to create it in outlook
      agent.agents_rdvs.future.each(&:sync_create_in_outlook_asynchronously)
    end
  end
end
