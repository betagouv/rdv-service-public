# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  self.deliver_later_queue_name = :mailers

  prepend IcsMultipartAttached

  default from: SUPPORT_EMAIL
  append_view_path Rails.root.join("app/views/mailers")
  layout "mailer"
  helper RdvSolidaritesInstanceNameHelper
  helper_method :domain

  def default_url_options
    super.merge(host: domain.dns_domain_name)
  end
end
