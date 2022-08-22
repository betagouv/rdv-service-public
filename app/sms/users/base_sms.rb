# frozen_string_literal: true

# Base class for all Sms sent to Users
class Users::BaseSms < ApplicationSms
  def initialize(rdv, user, token)
    super

    @phone_number = user.phone_number_formatted

    @rdv = rdv
    @provider = rdv.organisation&.territory&.sms_provider
    @key = rdv.organisation&.territory&.sms_configuration

    @tags = [
      ENV["APP"]&.gsub("-rdv-solidarites", ""), # shorter names
      "dpt-#{rdv.organisation&.departement_number}",
      "org-#{rdv.organisation&.id}",
      self.class.name.demodulize.underscore,
    ].compact

    @receipt_params[:rdv] = rdv
    @receipt_params[:user] = user
  end

  def domain_host
    @rdv.domain.dns_domain_name
  end
end
