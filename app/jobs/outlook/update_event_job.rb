# frozen_string_literal: true

module Outlook
  class UpdateEventJob < ApplicationJob
    def perform(agents_rdv)
      agents_rdv.update_outlook_event
    end
  end
end
