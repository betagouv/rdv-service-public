# frozen_string_literal: true

# See https://www.bigbinary.com/blog/rails-5-2-allows-mailers-to-use-custom-active-job-class
class CustomMailerDeliveryJob < ActionMailer::MailDeliveryJob
  # Only discard DeserializationError if it is caused by a ActiveRecord::RecordNotFound.
  # We don't want to discard a job when deserialization failed because of a DB failure for example.
  rescue_from ActiveJob::DeserializationError do |exception|
    if exception.cause.instance_of?(ActiveRecord::RecordNotFound)
      Rails.logger.error(exception.message)
    else
      raise exception
    end
  end
end
