# This file is used by Rack-based servers to start the application.

require "sentry-rails"

module Sentry
  class << self
    def capture_exception(exception, **options, &block)
      ::Rails.logger.error("logging from Sentry.capture_exception")
      ::Rails.logger.error("error is #{exception.inspect}")
      ::Rails.logger.error("options are #{options.inspect}")

      return unless initialized?

      get_current_hub.capture_exception(exception, **options, &block)
    end
  end
end

require_relative "config/environment"

run Rails.application
Rails.application.load_server
