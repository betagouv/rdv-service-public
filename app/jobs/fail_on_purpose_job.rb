class FailOnPurposeError < StandardError; end

class FailOnPurposeJob < ApplicationJob
  # self.log_arguments = false

  # retry_on(StandardError, wait: 20.seconds, attempts: 3, priority: DefaultJobBehaviour::PRIORITY_OF_RETRIES)

  # discard_on(FailOnPurposeError) { |job, error| job.capture_sentry_exception(error) }

  def perform(message: "This error was raised on purpose")
    Sentry.get_current_scope.set_fingerprint(["FailOnPurposeError", message])
    raise FailOnPurposeError, message
  end
end
