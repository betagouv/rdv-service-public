class FailOnPurposeError < StandardError; end

class FailOnPurposeJob < ApplicationJob
  # self.log_arguments = false

  def perform(message: "This error was raised on purpose")
    raise FailOnPurposeError, message
  end
end
