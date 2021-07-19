# frozen_string_literal: true

class InvalidMobilePhoneNumberError < StandardError; end

module TransactionalSms::BaseConcern
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.url_helpers

    attr_reader :user, :rdv

    delegate :phone_number_formatted, to: :user
  end

  def initialize(rdv, user)
    raise InvalidMobilePhoneNumberError, "#{user.phone_number_formatted} is not a valid mobile phone number" \
      unless user.phone_number_mobile?

    @user = user
    @rdv = rdv
  end

  def content
    [
      ApplicationController.helpers.rdv_solidarites_instance_name,
      raw_content
    ].compact
      .join("\n")
      .tr("áâãëẽêíïîĩóôõúûũçÀÁÂÃÈËẼÊÌÍÏÎĨÒÓÔÕÙÚÛŨ", "aaaeeeiiiiooouuucAAAAEEEEIIIIIOOOOUUUU")
      .gsub("œ", "oe")
  end

  def send!
    territory = Territory.find(@rdv.organisation_territory_id)
    SendTransactionalSmsService.perform_with(@user.phone_number_formatted, content, tags, territory.sms_provider, territory.sms_configuration)
  end

  def tags
    [
      ENV["APP"]&.gsub("-rdv-solidarites", ""), # shorter names
      "dpt-#{rdv.organisation_departement_number}",
      "org-#{rdv.organisation_id}",
      self.class.name.demodulize.underscore
    ].compact
  end

  def rdv_footer
    message = if rdv.phone?
                "RDV Téléphonique\n"
              elsif rdv.home?
                "RDV à domicile\n#{rdv.address}\n"
              else
                "#{rdv.address_complete}\n"
              end
    message += " pour #{rdv.users_full_names}" if rdv.should_display_users_in_sms?
    message += " avec #{rdv.agents_full_names} " if rdv.follow_up?
    message += "Infos et annulation: #{rdvs_shorten_url(host: ENV['HOST'])}"
    message += " / #{rdv.phone_number}" if rdv.phone_number.present?
    message
  end

  def to_s
    "content: #{content} | recipient: #{phone_number_formatted} | tags: #{tags.join(',')}"
  end
end
