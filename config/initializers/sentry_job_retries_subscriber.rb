# this logger sends warnings to Sentry on ActiveJob retries
# note: sentry-rails sends errors for final failures natively
ActiveSupport::Notifications.subscribe("enqueue_retry.active_job") do |_name, _started, _finished, _unique_id, data|
  job = data[:job]
  exception = data[:error]

  next if !exception || !job.capture_sentry_warning_for_retry?(exception)

  Sentry.capture_exception(exception, level: :warning)
end
