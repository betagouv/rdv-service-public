# frozen_string_literal: true

class SmsSender < BaseService
  class Timeout < StandardError; end

  class HttpError < StandardError; end

  class ApiError < StandardError; end

  SENDER_NAME = "RdvSoli"

  attr_reader :phone_number, :content, :tags, :provider, :key

  def initialize(phone_number, content, tags, provider, key) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    @phone_number = phone_number
    @content = formatted_content(content)
    @tags = tags

    if Rails.env.test?
      @provider = :debug_logger
      @key = nil
    elsif Rails.env.development?
      @provider = ENV["DEVELOPMENT_FORCE_SMS_PROVIDER"].presence || provider || ENV["DEFAULT_SMS_PROVIDER"].presence || :debug_logger
      @key = ENV["DEVELOPMENT_FORCE_SMS_PROVIDER_KEY"].presence || key || ENV["DEFAULT_SMS_PROVIDER_KEY"]
    else
      @provider = provider || ENV["DEFAULT_SMS_PROVIDER"].presence || :debug_logger
      @key = key || ENV["DEFAULT_SMS_PROVIDER_KEY"]
    end
  end

  def formatted_content(content)
    [
      ApplicationController.helpers.rdv_solidarites_instance_name,
      content
    ].compact
      .join("\n")
      .tr("áâãëẽêíïîĩóôõúûũçÀÁÂÃÈËẼÊÌÍÏÎĨÒÓÔÕÙÚÛŨ", "aaaeeeiiiiooouuucAAAAEEEEIIIIIOOOOUUUU")
      .gsub("œ", "oe")
  end

  def perform
    send("send_with_#{@provider}")
  end

  def self.split_content(content, max_length = 0)
    return [] if content.blank?
    return [content] if content.length < max_length

    content.chars.each_slice(max_length).map(&:join)
  end

  private

  def to_s
    conf = "provider : #{@provider}\nkey : #{@key}"
    message = "content: #{@content}\nphone_number: #{@phone_number}\ntags: #{@tags.join(',')}"
    "#{conf}\n#{message}"
  end

  # SendInBlue
  #
  def send_with_send_in_blue
    config = SibApiV3Sdk::Configuration.new
    config.api_key["api-key"] = @key
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
    response = Typhoeus::Request.new(
      "https://europe.ipx.com/restapi/v1/sms/send",
      method: :post,
      userpwd: @key,
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

    response = Typhoeus::Request.new(
      "https://contact-experience.com/ccv/webServicesCCV/SMS/sendSms.php",
      params: {
        number: @phone_number,
        msg: @content,
        devCode: @key,
        emetteur: replies_email # The parameter is called “emetteur” but it is actually an email where we can receive replies to the sms.
      }
    ).run

    raise Timeout if response.timed_out?
    raise HttpError, { message: self, response: "code: #{response.code}" } if response.failure?

    parsed_res = JSON.parse(response.body)
    raise ApiError, { message: self, response: parsed_res } if parsed_res["status"] == "KO"
  end

  # SFR with mail2SMS
  #
  def send_with_sfr_mail2sms
    Admins::Grc92Mailer.send_sms(@key, @phone_number, @content).deliver_now
  end

  # Clever Technologies
  #
  def send_with_clever_technologies
    response = Typhoeus::Request.new(
      "http://webservicesmultimedias.clever-is.fr/api/pushs",
      method: :post,
      headers: { "Content-Type": "application/json; charset=UTF-8", Authorization: "Basic #{Base64.encode64(@key).chomp}" },
      timeout: 5,
      body: {
        datas: {
          text: @content,
          number_list: @phone_number,
          encodage: 3
        }
      }.to_json
    ).run

    raise Timeout if response.timed_out?
    raise HttpError, { message: self, response: "code: #{response.code}" } if response.failure? || response.code == :http_returned_error

    parsed_res = JSON.parse(response.body)
    raise ApiError, { message: self, response: parsed_res } if response.code != 201
  end

  # Orange Contact Everyone
  #
  def send_with_orange_contact_everyone
    split_content(@content, 160).each do |message_part|
      response = Typhoeus::Request.new(
        "https://contact-everyone.orange-business.com/api/light/diffusions/sms",
        method: :post,
        headers: { "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8" },
        timeout: 5,
        body: {
          token: @key,
          to: @phone_number,
          msg: message_part
        }
      ).run

      raise Timeout if response.timed_out?
      raise HttpError, { message: self, response: "code: #{response.code}" } if response.failure? || response.code == :http_returned_error

      parsed_res = JSON.parse(response.body)
      raise ApiError, { message: self, response: parsed_res } if response.code != :success
    end
  end

  # DebugLogger
  #
  def send_with_debug_logger
    message = "content: #{@content} | recipient: #{@phone_number} | tags: #{@tags.join(',')}"
    Rails.logger.info("following SMS would have been sent in production environment: #{message}")
    Rails.logger.info("provider : #{@provider} configuration : #{@configuration}")
  end
end
