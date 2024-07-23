# monkey patch the default sentry_context method to :
# - selectively disable arguments logging
# - add the job_link to the GoodJob dashboard
# cf https://github.com/getsentry/sentry-ruby/blob/master/sentry-rails/lib/sentry/rails/active_job.rb#L67-L76

module SentryCustomContext
  def sentry_context(job)
    {
      job_id: job.job_id,
      queue_name: job.queue_name,
      job_link: job.job_link,
    }.merge(job.class.log_arguments ? { arguments: job.arguments } : {})
  end
end

Sentry::Rails::ActiveJobExtensions::SentryReporter.singleton_class.prepend SentryCustomContext
