class FailOnPurposeError < StandardError; end

class FailOnPurposeJob < ApplicationJob
  # self.log_arguments = false

  def perform(message: "This error was raised on purpose")
    Sentry.get_current_scope.set_fingerprint(["FailOnPurposeError", message])
    raise FailOnPurposeError, message
  end
end
