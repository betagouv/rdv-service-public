# frozen_string_literal: true

class HealthCheckJobError < StandardError; end

class FailingJob < ApplicationJob
  def perform(*_args, **_kwargs)
    raise HealthCheckJobError, "test error raised"
  end
end
