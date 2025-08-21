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
  class Client
    def event_from_exception(exception, hint = {})
      ::Rails.logger.error("logging from start of event_from_exception")
      return unless @configuration.sending_allowed?

      ignore_exclusions = hint.delete(:ignore_exclusions) { false }
      ::Rails.logger.error("logging from before second return")
      return if !ignore_exclusions && !@configuration.exception_class_allowed?(exception)

      integration_meta = Sentry.integrations[hint[:integration]]
      mechanism = hint.delete(:mechanism) { Mechanism.new }

      ::Rails.logger.error("logging from before building event")
      ErrorEvent.new(configuration: configuration, integration_meta: integration_meta).tap do |event|
        event.add_exception_interface(exception, mechanism: mechanism)
        event.add_threads_interface(crashed: true)
        event.level = :error
      end.tap do |result|
        ::Rails.logger.error("logging from end of event_from_exception")
        ::Rails.logger.error("result is #{result.inspect}")
      end
    end
  end
end

require_relative "config/environment"

run Rails.application
Rails.application.load_server
