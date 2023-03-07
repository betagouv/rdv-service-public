# frozen_string_literal: true

# Base class for all Sms sent to Users
class Users::BaseSms < ApplicationSms
  def initialize(rdv, user, token)
    super
    @rdv = rdv
    @user = user
    @token = token

    @receipt_params[:rdv] = rdv
    @receipt_params[:user] = user
  end

  attr_reader :content

  def deliver_later(queue: :sms, priority: 0)
    SmsJob.set(queue: queue, priority: priority).perform_later(
      sender_name: @rdv.domain.sms_sender_name,
      phone_number: @user.phone_number_formatted,
      content: content,
      provider: provider,
      api_key: api_key,
      receipt_params: @receipt_params
    )
  end

  private

  def provider
    if Rails.env.development? && ENV["DEVELOPMENT_FORCE_SMS_PROVIDER"].present?
      return ENV["DEVELOPMENT_FORCE_SMS_PROVIDER"]
    end

    @rdv.organisation&.territory&.sms_provider || ENV["DEFAULT_SMS_PROVIDER"].presence || :debug_logger
  end

  def api_key
    if Rails.env.development? && ENV["DEVELOPMENT_FORCE_SMS_PROVIDER_KEY"].present?
      return ENV["DEVELOPMENT_FORCE_SMS_PROVIDER_KEY"]
    end

    @rdv.organisation&.territory&.sms_configuration || ENV["DEFAULT_SMS_PROVIDER_KEY"]
  end

  def domain_host
    @rdv.domain.dns_domain_name
  end
end
