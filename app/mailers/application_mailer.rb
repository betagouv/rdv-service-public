class ApplicationMailer < ActionMailer::Base
  self.deliver_later_queue_name = :mailers

  include CommonMailer
  prepend IcsMultipartAttached

  append_view_path Rails.root.join("app/views/mailers")

  self.delivery_job = ApplicationMailerDeliveryJob
end
