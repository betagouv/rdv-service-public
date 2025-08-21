# This file is used by Rack-based servers to start the application.

require "sentry-rails"

module Sentry
  class Hub
    def capture_exception(exception, **options, &block)
      ::Rails.logger.error("logging from Sentry::Hub.capture_exception")
      if RUBY_PLATFORM == "java"
        check_argument_type!(exception, ::Exception, ::Java::JavaLang::Throwable)
      else
        check_argument_type!(exception, ::Exception)
      end

      ::Rails.logger.error("logging just before exception_captured")
      return if Sentry.exception_captured?(exception)

      ::Rails.logger.error("logging just before current_client")
      return unless current_client

      options[:hint] ||= {}
      options[:hint][:exception] = exception

      event = current_client.event_from_exception(exception, options[:hint])

      ::Rails.logger.error("logging just before event")
      return unless event

      current_scope.session&.update_from_exception(event.exception)

      ::Rails.logger.error("logging just before Sentry::Hub.capture_event")
      capture_event(event, **options, &block).tap do
        # mark the exception as captured so we can use this information to avoid duplicated capturing
        exception.instance_variable_set(Sentry::CAPTURED_SIGNATURE, true)
      end
    end
  end
end

require_relative "config/environment"

run Rails.application
Rails.application.load_server
