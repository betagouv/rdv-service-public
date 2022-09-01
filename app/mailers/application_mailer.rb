# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  self.deliver_later_queue_name = :mailers

  prepend IcsMultipartAttached

  append_view_path Rails.root.join("app/views/mailers")
  layout "mailer"
  helper RdvSolidaritesInstanceNameHelper
  helper_method :domain

  after_action { mail.from %("#{domain.name}" <#{default_from}>) }

  def default_url_options
    super.merge(host: domain.dns_domain_name)
  end

  private

  def default_from
    SUPPORT_EMAIL
  end
end
