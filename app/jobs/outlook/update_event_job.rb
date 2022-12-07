# frozen_string_literal: true

module Outlook
  class UpdateEventJob < ApplicationJob
    def perform(agents_rdv)
      Outlook::Event.new(agents_rdv: agents_rdv).update
    end
  end
end
