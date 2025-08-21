# This file is used by Rack-based servers to start the application.

require "sentry/rails"
module Sentry
  module Rails
    class RescuedExceptionInterceptor
      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) unless Sentry.initialized?

        begin
          @app.call(env)
        rescue StandardError => e
          ::Rails.logger.error("rescuing in RescuedExceptionInterceptor")
          ::Rails.logger.error("error is #{e.inspect}")
          env["sentry.rescued_exception"] = e if report_rescued_exceptions?
          raise e
        end
      end
    end
  end
end

require_relative "config/environment"

run Rails.application
Rails.application.load_server
