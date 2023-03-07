# frozen_string_literal: true

module Outlook
  class UpdateEventJob < ApplicationJob
    queue_as :outlook_sync

    def perform(agents_rdv)
      Outlook::Event.new(agents_rdv: agents_rdv).update
    end
  end
end
