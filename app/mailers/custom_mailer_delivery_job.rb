# frozen_string_literal: true

# See https://www.bigbinary.com/blog/rails-5-2-allows-mailers-to-use-custom-active-job-class
class CustomMailerDeliveryJob < ActionMailer::MailDeliveryJob
  include DefaultJobBehaviour

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

  # Don't log first failures to Sentry, to prevent noise
  # on temporary unavailability of an external service.
  def log_failure_to_sentry?(_exception)
    executions > 2
  end
end
