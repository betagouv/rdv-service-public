# frozen_string_literal: true

class NetsizeTimeout < StandardError; end

class NetsizeHttpError < StandardError; end

class NetsizeApiError < StandardError; end

class SendTransactionalSmsService < BaseService
  attr_reader :transactional_sms

  DEFAULT_SMS_PROVIDER = "netsize"
  DEFAULT_SMS_CONFIGURATION = {
    "api_url" => ENV["NETSIZE_API_USERPWD"],
    "user_pwd" => "https://europe.ipx.com/restapi/v1/sms/send"
  }.freeze

  SENDER_NAME = "RdvSoli"

  def initialize(transactional_sms)
    @transactional_sms = transactional_sms
    territory = @transactional_sms.rdv.organisation.territory
    @configuration = territory.sms_configuration || DEFAULT_SMS_CONFIGURATION

    @provider = :debug_logger
    @provider = territory.sms_provider || DEFAULT_SMS_PROVIDER if Rails.env.production?
    @provider = ENV["FORCE_SMS_PROVIDER"].to_sym if ENV["FORCE_SMS_PROVIDER"].present?
  end

  def perform
    send("send_with_#{@provider}")
  end

  private

  def send_with_send_in_blue
    config = SibApiV3Sdk::Configuration.new
    config.api_key = @configuration["api_key"]
    api_client = SibApiV3Sdk::ApiClient.new(config)
    SibApiV3Sdk::TransactionalSMSApi.new(api_client).send_transac_sms(
      SibApiV3Sdk::SendTransacSms.new(
        sender: SENDER_NAME,
        recipient: transactional_sms.phone_number_formatted,
        content: transactional_sms.content,
        tag: transactional_sms.tags.join(" ")
      )
    )
  end

  def send_with_netsize
    request = Typhoeus::Request.new(
      @configuration["api_url"],
      method: :post,
      userpwd: @configuration["user_pwd"],
      headers: { "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8" },
      timeout: 5,
      body: {
        destinationAddress: transactional_sms.phone_number_formatted,
        messageText: transactional_sms.content,
        originatingAddress: SENDER_NAME,
        originatorTON: 1,
        campaignName: transactional_sms.tags.join(" ").truncate(49),
        maxConcatenatedMessages: 10
      }
    )
    request.on_complete { netsize_on_complete(_1) }
    request.run
  end

  def netsize_on_complete(response)
    if response.success?
      parsed_res = JSON.parse(response.body)
      return if parsed_res["responseCode"].zero?

      ::Sentry.set_extras(parsed_res)
      raise NetsizeApiError, "HTTP 200, responseCode: #{parsed_res['responseCode']}, #{parsed_res['responseMessage']}"
    end

    raise NetsizeTimeout if response.timed_out?

    raise NetsizeHttpError, "code: #{response.code}, message: #{response.return_message}"
  end

  def send_with_debug_logger
    Rails.logger.debug("following SMS would have been sent in production environment: #{transactional_sms}")
    Rails.logger.debug("provider : #{@provider} configuration : #{@configuration}")
  end
end
