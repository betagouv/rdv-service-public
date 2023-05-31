# frozen_string_literal: true

require 'English'
class ExportJob < ApplicationJob
  queue_as :exports

  include GoodJob::ActiveJobExtensions::Concurrency

  # Run export jobs one at a time to keep it light on Postgres
  good_job_control_concurrency_with(
    perform_limit: 1,
    key: "ExportJob"
  )

  def log_failure_to_sentry?(exception)
    # When a job tries to run but their already is an
    # export job running, this exception is raised.
    # We should not send it to Sentry.
    !exception.is_a?(GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError)
  end
end
