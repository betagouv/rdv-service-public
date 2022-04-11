# frozen_string_literal: true

# Base class for all Sms sent to Users
class Users::BaseSms < ApplicationSms
  # These are limited to 11 characters
  DEFAULT_SENDER_NAME = "RdvSoli"
  CONSEILLER_NUMERIQUE_SENDER_NAME = "Conseil Num"

  def initialize(rdv, user)
    super

    @phone_number = user.phone_number_formatted

    @provider = rdv.organisation&.territory&.sms_provider
    @key = rdv.organisation&.territory&.sms_configuration
    @sender_name = sender_name(rdv)

    @tags = [
      ENV["APP"]&.gsub("-rdv-solidarites", ""), # shorter names
      "dpt-#{rdv.organisation&.departement_number}",
      "org-#{rdv.organisation&.id}",
      self.class.name.demodulize.underscore
    ].compact
  end

  private

  def sender_id(rdv)
    rdv.agents.first.conseiller_numerique? ? DEFAULT_SENDER_NAME : CONSEILLER_NUMERIQUE_SENDER_NAME
  end
end
