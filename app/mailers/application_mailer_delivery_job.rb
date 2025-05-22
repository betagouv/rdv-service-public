# See https://www.bigbinary.com/blog/rails-5-2-allows-mailers-to-use-custom-active-job-class
class ApplicationMailerDeliveryJob < ActionMailer::MailDeliveryJob
  include DefaultJobBehaviour

  queue_as :latency_30s

  # Only discard DeserializationError if it is caused by a ActiveRecord::RecordNotFound.
  # We don't want to discard a job when deserialization failed because of a DB failure for example.
  rescue_from ActiveJob::DeserializationError do |exception|
    Rails.logger.error("ActiveJob::DeserializationError rescue block executing...")
    Rails.logger.error("exception.inspect: #{exception.inspect}")
    Rails.logger.error("exception.cause.inspect: #{exception.cause.inspect}")
    Rails.logger.error("executions: #{executions}")

    if exception.cause.instance_of?(ActiveRecord::RecordNotFound)
      Rails.logger.error(exception.message)
    else
      Sentry.capture_exception(exception)
      Rails.logger.error("Calling retry_job")
      retry_job
    end
  end

  # Don't log first failures to Sentry, to prevent noise
  # on temporary unavailability of an external service.
  def capture_sentry_warning_for_retry?(_exception)
    super && executions > 2
  end
end
