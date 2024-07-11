class FailOnPurposeError < StandardError
  def sentry_fingerprint_with_message? = true
end

class FailOnPurposeJob < ApplicationJob
  # self.log_arguments = false

  def perform(message: "This error was raised on purpose")
    raise FailOnPurposeError, message
  end
end
