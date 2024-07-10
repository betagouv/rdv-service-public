module DefaultJobBehaviour
  extend ActiveSupport::Concern

  MAX_ATTEMPTS = 20
  PRIORITY_OF_RETRIES = 20

  included do
    # Include job metadata in Sentry context
    around_perform do |_job, block|
      job_context = { queue_name: queue_name, job_id: job_id, job_link: job_link }
      job_context[:arguments] = arguments if self.class.log_arguments
      Sentry.set_context(:job, job_context)
      Sentry.set_tags(job_link: job_link)
      block.call
    rescue StandardError => e
      Sentry.capture_exception(e) if log_failure_to_sentry?(e)
      raise # will be caught by the retry mechanism
    end

    # https://github.com/bensheldon/good_job#timeouts

    # This retry_on means:
    # "retry 20 times with an exponential backoff, then mark job as discarded"
    #
    # Exponential backoff is n^4, so wait times between retries will be as follows:
    # attempt:  1   2    3    4   5    6    7    8    9     10    11  12  13  14   15   16   17   18   19   20
    # backoff:  1s, 16s, 81s, 4m, 10m, 21m, 40m, 68m, 109m, 166m, 4h, 6h, 8h, 11h, 14h, 18h, 23h, 29h, 36h, 44h
    # it therefore takes more than 8 days for a job to be discarded
    retry_on(StandardError, wait: :exponentially_longer, attempts: MAX_ATTEMPTS, priority: PRIORITY_OF_RETRIES)

    # Makes sure every failed attempt is logged to Sentry
    # (see: https://github.com/bensheldon/good_job#retries)
  end

  private

  def log_failure_to_sentry?(_exception)
    executions <= 4 || executions == MAX_ATTEMPTS
  end

  def job_link
    @job_link ||= GoodJob::Engine.routes.url_helpers.job_url(id: job_id, host: Domain::RDV_SOLIDARITES.host_name)
  end

  def domain
    server_name = Sentry::Configuration.new.server_name
    server_name.match?(/rdv-mairie/) ? Domain::RDV_MAIRIE : Domain::RDV_SOLIDARITES
  end
end
