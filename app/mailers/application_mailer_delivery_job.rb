# See https://www.bigbinary.com/blog/rails-5-2-allows-mailers-to-use-custom-active-job-class
class ApplicationMailerDeliveryJob < ActionMailer::MailDeliveryJob
  include DefaultJobBehaviour

  # Don't log first failures to Sentry, to prevent noise
  # on temporary unavailability of an external service.
  def capture_sentry_warning_for_retry?(_exception)
    super && executions > 2
  end
end
