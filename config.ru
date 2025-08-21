# This file is used by Rack-based servers to start the application.

require "sentry-rails"

module Sentry
  class Hub
    def capture_exception(exception, **options, &block)
      if RUBY_PLATFORM == "java"
        check_argument_type!(exception, ::Exception, ::Java::JavaLang::Throwable)
      else
        check_argument_type!(exception, ::Exception)
      end

      return if Sentry.exception_captured?(exception)

      return unless current_client

      options[:hint] ||= {}
      options[:hint][:exception] = exception

      ::Rails.logger.error("logging just before event_from_exception")
      event = current_client.event_from_exception(exception, options[:hint])

      ::Rails.logger.error("logging just before event")
      return unless event

      current_scope.session&.update_from_exception(event.exception)

      capture_event(event, **options, &block).tap do
        # mark the exception as captured so we can use this information to avoid duplicated capturing
        exception.instance_variable_set(Sentry::CAPTURED_SIGNATURE, true)
      end
    end
  end
end

module Sentry
  module Utils
    module ExceptionCauseChain
      def self.exception_to_array(exception)
        ::Rails.logger.error("logging at start of ExceptionCauseChain")
        exceptions = [exception]

        while exception.cause
          exception = exception.cause
          ::Rails.logger.error("in loop, exception is #{exception.inspect}")
          break if exceptions.any? { |e| e.equal?(exception) }

          exceptions << exception
        end

        ::Rails.logger.error("logging at end of ExceptionCauseChain")
        exceptions
      rescue StandardError => e
        ::Rails.logger.error("error raised !")

        ::Rails.logger.error("raised error is: #{e.inspect}")
      end
    end
  end
end

require_relative "config/environment"

run Rails.application
Rails.application.load_server
