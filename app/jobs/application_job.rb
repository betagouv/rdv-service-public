# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # FIXME: uncomment this before merging
  # include DefaultJobBehaviour

  queue_as :default
end
