# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  self.deliver_later_queue_name = :mailers

  include CommonMailer
  prepend IcsMultipartAttached

  append_view_path Rails.root.join("app/views/mailers")

  # See https://www.bigbinary.com/blog/rails-5-2-allows-mailers-to-use-custom-active-job-class
  class CustomMailerDeliveryJob < ActionMailer::MailDeliveryJob
    discard_on ActiveJob::DeserializationError
  end
  self.delivery_job = CustomMailerDeliveryJob
end
