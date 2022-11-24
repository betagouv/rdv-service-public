# frozen_string_literal: true

module Outlook
  class MassCreateEventJob < ApplicationJob
    def perform(agent)
      agent.agents_rdvs.future.each(&:reflect_create_in_outlook)
    end
  end
end
