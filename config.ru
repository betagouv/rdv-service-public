# This file is used by Rack-based servers to start the application.

require "sentry-rails"

module Sentry
  module Rails
    class CaptureExceptions < Sentry::Rack::CaptureExceptions
      def capture_exception(exception, env)
        # the exception will be swallowed by ShowExceptions middleware
        return if show_exceptions?(exception, env) && !Sentry.configuration.rails.report_rescued_exceptions

        ::Rails.logger.error("rescuing in CaptureExceptions middleware")
        ::Rails.logger.error("error is #{exception.inspect}")
        ::Rails.logger.error("json of error is #{exception.to_json}")

        Sentry::Rails.capture_exception(exception).tap do |event|
          env[ERROR_EVENT_ID_KEY] = event.event_id if event
        end
      end
    end
  end
end
require_relative "config/environment"

run Rails.application
Rails.application.load_server
