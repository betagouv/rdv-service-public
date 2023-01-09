# frozen_string_literal: true

module Outlook
  class MassCreateEventJob < ApplicationJob
    def perform(agent)
      agent.agents_rdvs.future.each(&:sync_create_in_outlook_asynchronously)
    end
  end
end
