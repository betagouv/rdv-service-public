module DefaultJobBehaviour
  extend ActiveSupport::Concern

  MAX_ATTEMPTS = 20
  PRIORITY_OF_RETRIES = 20

  included do
    # This retry_on means:
    # "retry 20 times with an exponential backoff, then mark job as discarded"
    #
    # Exponential backoff is n^4, so wait times between retries will be as follows:
    # attempt:  1   2    3    4   5    6    7    8    9     10    11  12  13  14   15   16   17   18   19   20
    # backoff:  1s, 16s, 81s, 4m, 10m, 21m, 40m, 68m, 109m, 166m, 4h, 6h, 8h, 11h, 14h, 18h, 23h, 29h, 36h, 44h
    # sum: (1..20).map { _1 ** 4 }.sum.to_f / 60 / 60 / 24 ~= 8
    # it therefore takes more than 8 days for a job to be discarded
    retry_on(StandardError, wait: :exponentially_longer, attempts: MAX_ATTEMPTS, priority: PRIORITY_OF_RETRIES)

    before_perform :set_sentry_context
  end

  # cf config/initializers/sentry_job_retries_subscriber.rb
  # where we configure capturing warnings on retries
  def capture_sentry_warning_for_retry?(_exception)
    executions <= 4
  end

  def job_link
    good_job_domain = ENV["APP"]&.match?(/rdv-mairie/) ? Domain::RDV_MAIRIE : Domain::RDV_SOLIDARITES
    GoodJob::Engine.routes.url_helpers.job_url(id: job_id, host: good_job_domain.host_name)
  end

  def set_sentry_context
    Sentry.set_context(:rdv_job, queue_name:, job_link:)
  end

  # cette méthode est appelée depuis config/initializers/sentry_job_retries_subscriber.rb
  # et depuis les discard_on custom dans les jobs
  def capture_sentry_exception(exception, level: :error)
    # adapted from https://github.com/getsentry/sentry-ruby/blob/master/sentry-rails/lib/sentry/rails/active_job.rb#L47-L54
    Sentry.capture_exception(
      exception,
      extra: Sentry::Rails::ActiveJobExtensions::SentryReporter.sentry_context(self),
      level:,
      tags: { job_id:, provider_job_id: }
    )
  end
end
