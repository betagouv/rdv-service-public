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

      ::Rails.logger.error("logging from before building event")
      ErrorEvent.new(configuration: configuration, integration_meta: integration_meta).tap do |event|
        ::Rails.logger.error("logging from before add_exception_interface")
        event.add_exception_interface(exception, mechanism: mechanism)
        ::Rails.logger.error("logging from before add_threads_interface")
        event.add_threads_interface(crashed: true)
        event.level = :error
      end.tap do |_result|
        ::Rails.logger.error("logging from end of event_from_exception")
      end
    end
  end
end

require_relative "config/environment"

run Rails.application
Rails.application.load_server
