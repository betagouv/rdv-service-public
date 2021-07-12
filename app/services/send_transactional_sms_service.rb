# frozen_string_literal: true

class SendTransactionalSmsService < BaseService
  class Timeout < StandardError; end

  class HttpError < StandardError; end

  class ApiError < StandardError; end

  SENDER_NAME = "RdvSoli"

  def initialize(phone_number, content, tags, provider = nil, configuration = nil)
    @phone_number = phone_number
    @content = content
    @tags = tags

    @provider = if Rails.env.test?
                  :debug_logger
                else
                  ENV["DEVELOPMENT_FORCE_SMS_PROVIDER"].presence || provider || ENV["DEFAULT_SMS_PROVIDER"].presence || :debug_logger
                end
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

  # SendInBlue
  #
  def send_with_send_in_blue
    config = SibApiV3Sdk::Configuration.new
    config.api_key["api-key"] = @configuration["api_key"]
    api_client = SibApiV3Sdk::ApiClient.new(config)
    begin
      SibApiV3Sdk::TransactionalSMSApi.new(api_client).send_transac_sms(
        SibApiV3Sdk::SendTransacSms.new(
          sender: SENDER_NAME,
          recipient: @phone_number,
          content: @content,
          tag: @tags.join(" ")
        )
      )
    rescue SibApiV3Sdk::ApiError => e
      raise ApiError, { message: self, response: "#{e.code} #{e.response_body}" }
    end
  end

  # NetSize
  #
  def send_with_netsize
    base_url = @configuration["api_url"].presence || "https://europe.ipx.com/restapi/v1/sms/send"
    response = Typhoeus::Request.new(
      base_url,
      method: :post,
      userpwd: @configuration["api_key"],
      headers: { "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8" },
      timeout: 5,
      body: {
        destinationAddress: @phone_number,
        messageText: @content,
        originatingAddress: SENDER_NAME,
        originatorTON: 1,
        campaignName: @tags.join(" ").truncate(49),
        maxConcatenatedMessages: 10
      }
    ).run

    raise Timeout if response.timed_out?
    raise HttpError, { message: self, response: "code: #{response.code}" } if response.failure?

    parsed_res = JSON.parse(response.body)
    raise ApiError, { message: self, response: parsed_res } unless parsed_res["responseCode"].zero?
  end

  # Contact Experience
  #
  def send_with_contact_experience
    replies_email = CONTACT_EMAIL
    base_url = @configuration["api_url"].presence || "https://contact-experience.com/ccv/webServicesCCV/SMS/sendSms.php"

    response = Typhoeus::Request.new(
      base_url,
      params: {
        number: @phone_number,
        msg: @content,
        devCode: @configuration["api_key"],
        emetteur: replies_email # The parameter is called “emetteur” but it is actually an email where we can receive replies to the sms.
      }
    ).run

    raise Timeout if response.timed_out?
    raise HttpError, { message: self, response: "code: #{response.code}" } if response.failure?

    parsed_res = JSON.parse(response.body)
    raise ApiError, { message: self, response: parsed_res } if parsed_res["status"] == "KO"
  end
end
