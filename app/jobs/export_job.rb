# frozen_string_literal: true

class ExportJob < ApplicationJob
  queue_as :exports

  include GoodJob::ActiveJobExtensions::Concurrency

  # Run export jobs one at a time to keep it light on Postgres
  good_job_control_concurrency_with(
    perform_limit: 1,
    key: "ExportJob"
  )

  def log_failure_to_sentry?(exception)
    # This exception is raised by the concurrency control system
    # when a job tries to execute but another job is already running.
    # It is thus only used as a control flow mechanism, and should not e sent to Sentry.
    !exception.is_a?(GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError)
  end
end
