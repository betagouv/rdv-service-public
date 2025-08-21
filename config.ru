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
          ::Rails.logger.error("logging: about to build with stacktrace")
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
      ::Rails.logger.error("logging from start of build_with_stacktrace")
      stacktrace = stacktrace_builder.build(backtrace: exception.backtrace)

      ::Rails.logger.error("logging from middle of build_with_stacktrace")
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
  end
end

require_relative "config/environment"

run Rails.application
Rails.application.load_server
