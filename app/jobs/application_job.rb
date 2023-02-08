# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  queue_as :default
  queue_with_priority 0
end
