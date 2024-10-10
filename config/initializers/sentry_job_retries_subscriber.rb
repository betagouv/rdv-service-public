# this logger sends warnings to Sentry on ActiveJob retries
# note: sentry-rails sends errors for final failures natively
ActiveSupport::Notifications.subscribe("enqueue_retry.active_job") do |_name, _started, _finished, _unique_id, data|
  job = data[:job]
  exception = data[:error]

  next if !exception || !job.capture_sentry_warning_for_retry?(exception)

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
