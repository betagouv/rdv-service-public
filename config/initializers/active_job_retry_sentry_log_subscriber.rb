# monkey patch the default sentry_context method so we can selectively disable arguments logging
class Sentry::Rails::ActiveJobExtensions::SentryReporter
  def self.sentry_context(job)
    { job_id: job.job_id, queue_name: job.queue_name }
      .merge(job.class.log_arguments ? { arguments: job.arguments } : {})
  end
end

class BullError < StandardError; end

class ActiveJobRetrySentryLogSubscriber < ActiveSupport::LogSubscriber
  def enqueue_retry(event)
    job = event.payload[:job]
    exception = event.payload[:error]

    return if !exception || !job.capture_sentry_warning_for_retry?(exception)

    # adapted from https://github.com/getsentry/sentry-ruby/blob/master/sentry-rails/lib/sentry/rails/active_job.rb#L47-L54
    Sentry.capture_exception(
      exception,
      extra: Sentry::Rails::ActiveJobExtensions::SentryReporter.sentry_context(job),
      level: :warning,
      tags: {
        job_id: job.job_id,
        provider_job_id: job.provider_job_id,
      }
    )
  end
end

ActiveJobRetrySentryLogSubscriber.attach_to :active_job
