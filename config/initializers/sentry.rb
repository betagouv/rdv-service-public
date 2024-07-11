Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN_RAILS"]

  # Most 4xx errors are excluded by default.
  # See Sentry::Configuration::IGNORE_DEFAULT
  # and Sentry::Rails::IGNORE_DEFAULT
  # Cf https://docs.sentry.io/platforms/ruby/configuration/options/#optional-settings
  # config.excluded_exceptions += []

  # cf docs/5-role-de-vigie.md
  # et https://docs.sentry.io/platforms/ruby/guides/rails/configuration/filtering/
  config.excluded_exceptions -= ["ActiveRecord::RecordNotFound"]

  config.before_send = lambda do |event, hint|
    exception = hint[:exception]
    referer = event.request&.headers&.fetch("Referer", "")
    internal_referer = Domain::ALL.map(&:host_name).any? { referer&.include?(_1) }
    return if exception.is_a?(ActiveRecord::RecordNotFound) && !internal_referer

    if exception.respond_to?(:sentry_fingerprint_with_message?) && exception.sentry_fingerprint_with_message?
      # when the stacktrace is present, Sentry uses it exclusively to group issues
      # cf https://docs.sentry.io/concepts/data-management/event-grouping/#grouping-by-stack-trace
      # for webhook errors we want to group by message (which contain codes and URLs)
      # cf https://docs.sentry.io/platforms/ruby/usage/sdk-fingerprinting/#group-errors-with-greater-granularity
      event.fingerprint = ["{{default}}", exception.message]
    end

    event
  end

  # Ces erreurs déclenchent un retry :
  # https://github.com/bensheldon/good_job?tab=readme-ov-file#how-concurrency-controls-work
  # Il ne nous est pas utile de les voir dans Sentry puisqu'elles ont un rôle de contrôle de flux.
  config.excluded_exceptions += ["GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError"]
end

# monkey patch the default sentry_context method so we can selectively disable arguments logging
# cf https://github.com/getsentry/sentry-ruby/blob/master/sentry-rails/lib/sentry/rails/active_job.rb#L67-L76
class Sentry::Rails::ActiveJobExtensions::SentryReporter
  def self.sentry_context(job)
    {
      job_id: job.job_id,
      queue_name: job.queue_name,
      job_link: job.job_link,
    }.merge(job.class.log_arguments ? { arguments: job.arguments } : {})
  end
end
