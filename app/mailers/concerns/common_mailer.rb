# frozen_string_literal: true

# Ce concern permet d'inclure des comportements à la fois dans
# ApplicationMailer et dans CustomDeviseMailer, qui ont toutes
# deux des classe mères.
module CommonMailer
  extend ActiveSupport::Concern

  included do
    layout "mailer"
    helper RdvSolidaritesInstanceNameHelper
    helper_method :domain

    after_action { mail.from %("#{domain.name}" <#{default_from}>) }
  end

  private

  def default_url_options
    super.merge(host: domain.dns_domain_name)
  end

  def default_from
    SUPPORT_EMAIL
  end
end
