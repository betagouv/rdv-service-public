# frozen_string_literal: true

module DefaultJobBehaviour
  extend ActiveSupport::Concern

  included do
    # Include job metadata in Sentry context
    around_perform do |_job, block|
      Sentry.with_scope do |scope|
        scope.set_context(:job, { job_id: job_id, queue_name: queue_name, arguments: arguments })
        block.call
      end
    end

    # This retry_on means:
    # "retry 20 times with an exponential backoff, then mark job as discarded"
    #
    # Exponential backoff is n^4, so wait times between retries will be as follows:
    # attempt:  1   2    3    4   5    6    7    8    9     10    11  12  13  14   15   16   17   18   19   20
    # backoff:  1s, 16s, 81s, 4m, 10m, 21m, 40m, 68m, 109m, 166m, 4h, 6h, 8h, 11h, 14h, 18h, 23h, 29h, 36h, 44h
    retry_on(StandardError, wait: :exponentially_longer, attempts: 20)

    # Makes sure every failed attempt is logged to Sentry
    # (see: https://github.com/bensheldon/good_job#retries)
    around_perform do |job, block|
      block.call
    rescue StandardError => e
      Sentry.capture_exception(e) if job.log_failure_to_sentry?
      raise # will be caught by the retry mechanism
    end
  end

  def log_failure_to_sentry?
    true
  end
end
