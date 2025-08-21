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
  class Client
    def capture_event(event, scope, hint = {})
      ::Rails.logger.error("logging from Sentry::Client#capture_event")
      ::Rails.logger.error("caller is #{caller.inspect}")
      ::Rails.logger.error("event is #{event.inspect}")

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

module Sentry
  class Transport
    def send_envelope(envelope)
      ::Rails.logger.error("logging from Sentry::Transport#send_envelope")
      ::Rails.logger.error("envelope is #{envelope.inspect}")
      ::Rails.logger.error("caller is #{caller.inspect}")
      reject_rate_limited_items(envelope)

      return if envelope.items.empty?

      data, serialized_items = serialize_envelope(envelope)

      if data
        log_debug("[Transport] Sending envelope with items [#{serialized_items.map(&:type).join(', ')}] #{envelope.event_id} to Sentry")
        send_data(data)
      end
    end
  end
end
require_relative "config/environment"

run Rails.application
Rails.application.load_server
