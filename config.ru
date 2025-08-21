# This file is used by Rack-based servers to start the application.

require "sentry-rails"

module Sentry
  class SingleExceptionInterface
    def initialize(exception:, mechanism:, stacktrace: nil)
      @type = exception.class.to_s
      exception_message =
        if exception.respond_to?(:detailed_message)
          ::Rails.logger.error("logging from before detailed message")
          exception.detailed_message(highlight: false)
        else
          exception.message || ""
        end
      ::Rails.logger.error("logging from before turning into string")
      exception_message = exception_message.inspect unless exception_message.is_a?(String)

      @value = Utils::EncodingHelper.encode_to_utf_8(exception_message.byteslice(0..Event::MAX_MESSAGE_SIZE_IN_BYTES))

      @module = exception.class.to_s.split("::")[0...-1].join("::")
      @thread_id = Thread.current.object_id
      @stacktrace = stacktrace
      @mechanism = mechanism
    end
  end
end

require_relative "config/environment"

run Rails.application
Rails.application.load_server
