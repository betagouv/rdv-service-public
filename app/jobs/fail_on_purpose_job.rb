class FailOnPurposeError < StandardError; end

class FailOnPurposeJob < ApplicationJob
  def perform(message: "This error was raised on purpose")
    raise FailOnPurposeError, message
  end
end
