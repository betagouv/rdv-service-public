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

module Sentry
  class Hub
    def capture_exception(exception, **options, &block)
      ::Rails.logger.error("logging from Sentry::Hub.capture_exception")
      if RUBY_PLATFORM == "java"
        check_argument_type!(exception, ::Exception, ::Java::JavaLang::Throwable)
      else
        check_argument_type!(exception, ::Exception)
      end

      return if Sentry.exception_captured?(exception)

      return unless current_client

      options[:hint] ||= {}
      options[:hint][:exception] = exception

      event = current_client.event_from_exception(exception, options[:hint])

      return unless event

      current_scope.session&.update_from_exception(event.exception)

      capture_event(event, **options, &block).tap do
        # mark the exception as captured so we can use this information to avoid duplicated capturing
        exception.instance_variable_set(Sentry::CAPTURED_SIGNATURE, true)
      end
    end

    def capture_event(event, **options, &block)
      ::Rails.logger.error("logging from Sentry::Hub.capture_event")
      check_argument_type!(event, Sentry::Event)

      return unless current_client

      hint = options.delete(:hint) || {}
      scope = current_scope.dup

      if block
        block.call(scope)
      elsif custom_scope = options[:scope]
        scope.update_from_scope(custom_scope)
      elsif !options.empty?
        unsupported_option_keys = scope.update_from_options(**options)

        unless unsupported_option_keys.empty?
          configuration.log_debug <<~MSG
            Options #{unsupported_option_keys} are not supported and will not be applied to the event.
            You may want to set them under the `extra` option.
          MSG
        end
      end

      # Dans le cas du bug, on n'arrive pas jusqu'à cette ligne
      event = current_client.capture_event(event, scope, hint)

      if event && configuration.debug
        configuration.log_debug(event.to_json_compatible)
      end

      @last_event_id = event&.event_id if event.is_a?(Sentry::ErrorEvent)
      event
    end
  end
end

module Sentry
  class Client
    def capture_event(event, scope, hint = {})
      ::Rails.logger.error("logging from Sentry::Client#capture_event")

      return unless configuration.sending_allowed?

      if event.is_a?(ErrorEvent) && !configuration.sample_allowed?
        transport.record_lost_event(:sample_rate, "error")
        return
      end

      event_type = event.is_a?(Event) ? event.type : event["type"]
      data_category = Envelope::Item.data_category(event_type)

      is_transaction = event.is_a?(TransactionEvent)
      spans_before = is_transaction ? event.spans.size : 0

      event = scope.apply_to_event(event, hint)

      if event.nil?
        log_debug("Discarded event because one of the event processors returned nil")
        transport.record_lost_event(:event_processor, data_category)
        transport.record_lost_event(:event_processor, "span", num: spans_before + 1) if is_transaction
        return
      elsif is_transaction
        spans_delta = spans_before - event.spans.size
        transport.record_lost_event(:event_processor, "span", num: spans_delta) if spans_delta > 0
      end

      if async_block = configuration.async
        dispatch_async_event(async_block, event, hint)
      elsif configuration.background_worker_threads != 0 && hint.fetch(:background, true)
        unless dispatch_background_event(event, hint)
          transport.record_lost_event(:queue_overflow, data_category)
          transport.record_lost_event(:queue_overflow, "span", num: spans_before + 1) if is_transaction
        end
      else
        send_event(event, hint)
      end

      event
    rescue StandardError => e
      log_error("Event capturing failed", e, debug: configuration.debug)
      nil
    end
  end
end

require_relative "config/environment"

run Rails.application
Rails.application.load_server
