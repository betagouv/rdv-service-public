class ApplicationMailer < ActionMailer::Base
  prepend IcsMultipartAttached

  layout "mailer"
  helper RdvSolidaritesInstanceNameHelper
  helper_method :domain

  after_action :set_default_from_with_display_name
  append_view_path Rails.root.join("app/views/mailers")

  self.deliver_later_queue_name = :mailers
  self.delivery_job = ApplicationMailerDeliveryJob

  private

  def default_url_options
    super.merge(host: domain.host_name)
  end

  def set_default_from_with_display_name
    mail.from %("#{domain.name}" <#{default_from}>) if mail.from.blank?
  end

  def default_from
    domain.support_email
  end
end
