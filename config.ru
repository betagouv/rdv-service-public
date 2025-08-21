# This file is used by Rack-based servers to start the application.

require "sentry-rails"

module Sentry
  class ExceptionInterface < Interface
    def self.build(exception:, stacktrace_builder:, mechanism:)
      exceptions = Sentry::Utils::ExceptionCauseChain.exception_to_array(exception).reverse
      processed_backtrace_ids = Set.new

      exceptions = exceptions.map do |e|
        ::Rails.logger.error("logging from loop: e is #{e.inspect}")
        ::Rails.logger.error("e properties are backtrace: #{e.backtrace.inspect}, ")

        if e.backtrace && !processed_backtrace_ids.include?(e.backtrace.object_id)
          processed_backtrace_ids << e.backtrace.object_id
          ::Rails.logger.error("logging: about to build with stacktrace")
          SingleExceptionInterface.build_with_stacktrace(exception: e, stacktrace_builder: stacktrace_builder, mechanism: mechanism)
        else
          ::Rails.logger.error("logging: about to initialize")
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
