# frozen_string_literal: true

module Outlook
  class MassCreateEventJob < ApplicationJob
    def perform(agent)
      agent.agents_rdv.future.each do |agents_rdv|
        Outlook::CreateEventJob.perform_later(agents_rdv)
      end
    end
  end
end
