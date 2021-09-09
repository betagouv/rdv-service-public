# frozen_string_literal: true

# Base class for all Sms sent to Users
class Users::BaseSms < ApplicationSms
  def initialize(rdv_payload, user)
    super

    rdv_payload = OpenStruct.new(rdv_payload)

    @phone_number = user.phone_number_formatted

    territory = Territory.find(rdv_payload.organisation_territory_id)
    @provider = territory.sms_provider
    @key = territory.sms_configuration

    @tags = [
      ENV["APP"]&.gsub("-rdv-solidarites", ""), # shorter names
      "dpt-#{rdv_payload.organisation_departement_number}",
      "org-#{rdv_payload.organisation_id}",
      self.class.name.demodulize.underscore
    ].compact
  end
end
