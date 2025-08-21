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
