class OnPurposeError < StandardError
end

class FailOnPurposeJob < ApplicationJob
  def perform
    raise OnPurposeError, "Test adrien - I failed on purpose"
  end
end
