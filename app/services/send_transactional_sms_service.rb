class SendTransactionalSmsService < BaseService
  attr_reader :transactional_sms

  SENDER_NAME = "RdvSoli".freeze

  def initialize(transactional_sms)
    @transactional_sms = transactional_sms
  end

  def perform
    send("send_with_#{sms_provider}")
  end

  private

  def sms_provider
    if ENV["FORCE_SMS_PROVIDER"]
      ENV["FORCE_SMS_PROVIDER"].to_sym
    elsif Rails.env.production?
      :netsize
    else
      :debug_logger
    end
  end

  def send_with_send_in_blue
    SibApiV3Sdk::TransactionalSMSApi.new.send_transac_sms(
      SibApiV3Sdk::SendTransacSms.new(
        sender: SENDER_NAME,
        recipient: transactional_sms.phone_number_formatted,
        content: transactional_sms.content,
        tag: transactional_sms.tags.join(" ")
      )
    )
  end

  def send_with_netsize; end

  def send_with_debug_logger
    Rails.logger.debug("following SMS would have been sent in production environment: #{transactional_sms}")
  end
end
