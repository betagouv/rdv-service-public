# frozen_string_literal: true

module Outlook
  class DestroyEventJob < ApplicationJob
    def perform(agents_rdv)
      agents_rdv.destroy_outlook_event
      agents_rdv.update(outlook_id: nil)
    end
  end
end
