# frozen_string_literal: true

module Outlook
  class CreateEventJob < ApplicationJob
    def perform(rdv, agent)
      outlook_event = rdv.create_outlook_event(agent, rdv.outlook_payload(agent))
    end
  end
end
