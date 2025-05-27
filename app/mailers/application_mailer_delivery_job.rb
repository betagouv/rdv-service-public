# See https://www.bigbinary.com/blog/rails-5-2-allows-mailers-to-use-custom-active-job-class

class MailArgumentError < StandardError; end

class ApplicationMailerDeliveryJob < ActionMailer::MailDeliveryJob
  include DefaultJobBehaviour

  queue_as :latency_30s

  # Only discard DeserializationError if it is caused by a ActiveRecord::RecordNotFound.
  # We don't want to discard a job when deserialization failed because of a DB failure for example.
  rescue_from ActiveJob::DeserializationError do |exception|
    if exception.cause.instance_of?(ActiveRecord::RecordNotFound)
      Rails.logger.error(exception.message)
    else
      Sentry.capture_exception(exception)
      retry_job
    end
  end

  # to catch a specific ArgumentError by its message, we need to rescue and re-raise.
  # using discard_on or rescue_from is too broad and does not allow re-raising
  around_perform do |_job, block|
    block.call
  rescue ArgumentError => e
    if e.message.match(/SMTP To address may not be blank/)
      raise MailArgumentError, e.message
    else
      raise e
    end
  end

  discard_on MailArgumentError do |_job, exception|
    Sentry.capture_exception(exception)
  end

  # Don't log first failures to Sentry, to prevent noise
  # on temporary unavailability of an external service.
  def capture_sentry_warning_for_retry?(_exception)
    super && executions > 2
  end
end
