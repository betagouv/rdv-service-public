# frozen_string_literal: true

class NetsizeTimeout < StandardError; end

class NetsizeHttpError < StandardError; end

class NetsizeApiError < StandardError; end

class SendTransactionalSmsService < BaseService
  SENDER_NAME = "RdvSoli"

  def initialize(phone_number, content, tags, provider = nil, configuration = nil)
    @phone_number = phone_number
    @content = content
    @tags = tags

    @provider = ENV["DEVELOPMENT_FORCE_SMS_PROVIDER"].presence || provider || ENV["DEFAULT_SMS_PROVIDER"].presence || :debug_logger
    default_configuration = {
      "api_url" => ENV["DEFAULT_SMS_PROVIDER_API_URL"],
      "api_key" => ENV["DEFAULT_SMS_PROVIDER_KEY"]
    }
    @configuration = configuration || default_configuration
  end

  def perform
    send("send_with_#{@provider}")
  end

  private

  def to_s
    conf = "provider : #{@provider}\nconfiguration : #{@configuration}"
    message = "content: #{@content}\nphone_number: #{@phone_number}\ntags: #{@tags.join(',')}"
    "#{conf}\n#{message}"
  end

  # DebugLogger
  #
  def send_with_debug_logger
    Rails.logger.info("SMS DebugLogger: this would have been sent: #{self}")
  end

  def send_with_send_in_blue
    config = SibApiV3Sdk::Configuration.new
    config.api_key = @configuration["api_key"]
    api_client = SibApiV3Sdk::ApiClient.new(config)
    SibApiV3Sdk::TransactionalSMSApi.new(api_client).send_transac_sms(
      SibApiV3Sdk::SendTransacSms.new(
        sender: SENDER_NAME,
        recipient: @phone_number_formatted,
        content: @content,
        tag: @tags.join(" ")
      )
    )
  end

  def send_with_netsize
    request = Typhoeus::Request.new(
      @configuration["api_url"],
      method: :post,
      userpwd: @configuration["api_key"],
      headers: { "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8" },
      timeout: 5,
      body: {
        destinationAddress: @phone_number_formatted,
        messageText: @content,
        originatingAddress: SENDER_NAME,
        originatorTON: 1,
        campaignName: @tags.join(" ").truncate(49),
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
end
