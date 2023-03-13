# frozen_string_literal: true

module Outlook
  class DestroyEventJob < ApplicationJob
    queue_as :outlook_sync

    def perform(outlook_id, agent); end
  end
end
