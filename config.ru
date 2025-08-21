# This file is used by Rack-based servers to start the application.

require "sentry-rails"

module Sentry
  class ExceptionInterface < Interface
    def self.build(exception:, stacktrace_builder:, mechanism:)
      exceptions = Sentry::Utils::ExceptionCauseChain.exception_to_array(exception).reverse
      processed_backtrace_ids = Set.new

      exceptions = exceptions.map do |e|
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

module Sentry
  class SingleExceptionInterface
    def self.build_with_stacktrace(exception:, stacktrace_builder:, mechanism:)
      stacktrace = stacktrace_builder.build(backtrace: exception.backtrace)

      if locals = exception.instance_variable_get(:@sentry_locals)
        locals.each do |k, v|
          locals[k] =
            begin
              v = v.inspect unless v.is_a?(String)

              if v.length >= MAX_LOCAL_BYTES
                v = v.byteslice(0..MAX_LOCAL_BYTES - 1) + OMISSION_MARK
              end

              Utils::EncodingHelper.encode_to_utf_8(v)
            rescue StandardError
              PROBLEMATIC_LOCAL_VALUE_REPLACEMENT
            end
        end

        stacktrace.frames.last.vars = locals
      end

      ::Rails.logger.error("logging from end of build_with_stacktrace")
      new(exception: exception, stacktrace: stacktrace, mechanism: mechanism)
    end

    def initialize(exception:, mechanism:, stacktrace: nil)
      ::Rails.logger.error("logging from start of initialize")
      @type = exception.class.to_s
      exception_message =
        if exception.respond_to?(:detailed_message)
          exception.detailed_message(highlight: false)
        else
          exception.message || ""
        end
      exception_message = exception_message.inspect unless exception_message.is_a?(String)

      ::Rails.logger.error("logging from before value")
      @value = Utils::EncodingHelper.encode_to_utf_8(exception_message.byteslice(0..Event::MAX_MESSAGE_SIZE_IN_BYTES))

      ::Rails.logger.error("logging from before module")
      @module = exception.class.to_s.split("::")[0...-1].join("::")
      @thread_id = Thread.current.object_id
      @stacktrace = stacktrace
      @mechanism = mechanism
      ::Rails.logger.error("logging from end of initialize")
    end
  end
end

require_relative "config/environment"

run Rails.application
Rails.application.load_server
