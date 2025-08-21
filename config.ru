# This file is used by Rack-based servers to start the application.

require "sentry-rails"

module Sentry
  class Client
    def event_from_exception(exception, hint = {})
      return unless @configuration.sending_allowed?

      ignore_exclusions = hint.delete(:ignore_exclusions) { false }
      return if !ignore_exclusions && !@configuration.exception_class_allowed?(exception)

      integration_meta = Sentry.integrations[hint[:integration]]
      mechanism = hint.delete(:mechanism) { Mechanism.new }

      ErrorEvent.new(configuration: configuration, integration_meta: integration_meta).tap do |event|
        ::Rails.logger.error("logging from before add_exception_interface")
        event.add_exception_interface(exception, mechanism: mechanism)
        ::Rails.logger.error("logging from before add_threads_interface")
        event.add_threads_interface(crashed: true)
        event.level = :error
      end
    end
  end
end

module Sentry
  class ExceptionInterface < Interface
    def self.build(exception:, stacktrace_builder:, mechanism:)
      ::Rails.logger.error("logging from start of build")
      exceptions = Sentry::Utils::ExceptionCauseChain.exception_to_array(exception).reverse
      processed_backtrace_ids = Set.new

      ::Rails.logger.error("logging from before loop")
      exceptions = exceptions.map do |e|
        ::Rails.logger.error("logging from loop: e is #{e.inspect}")
        if e.backtrace && !processed_backtrace_ids.include?(e.backtrace.object_id)
          processed_backtrace_ids << e.backtrace.object_id
          SingleExceptionInterface.build_with_stacktrace(exception: e, stacktrace_builder: stacktrace_builder, mechanism: mechanism)
        else
          SingleExceptionInterface.new(exception: exception, mechanism: mechanism)
        end
      end

      ::Rails.logger.error("logging from end of build")
      new(exceptions: exceptions)
    end
  end
end

require_relative "config/environment"

run Rails.application
Rails.application.load_server
