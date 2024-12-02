class SmsSender < BaseService
  class SmsSenderFailure < StandardError; end

  attr_reader :phone_number, :content, :provider, :api_key

  def initialize(sender_name, phone_number, content, provider, api_key, receipt_params) # rubocop:disable Metrics/ParameterLists
    @sender_name = sender_name
    @phone_number = phone_number
    @content = formatted_content(content)
    @provider = provider
    @api_key = api_key
    @receipt_params = receipt_params
  end

  def formatted_content(content)
    [
      ApplicationController.helpers.rdv_solidarites_instance_name,
      content,
    ].compact
      .join("\n")
      .tr("áâãçëẽêíïîĩóôõúûũÀÁÂÃÇÈËẼÊÌÍÏÎĨÒÓÔÕÙÚÛŨ", "aaaceeeiiiiooouuuAAAACEEEEIIIIIOOOOUUUU")
      .gsub("œ", "oe")
  end

  def perform
    case @provider.to_sym
    when :netsize
      send_with_netsize
    when :clever_technologies
      send_with_clever_technologies
    when :sfr_mail2sms
      send_with_sfr_mail2sms
    when :debug_logger
      send_with_debug_logger
    else
      raise "Invalid provider: #{@provider.inspect}"
    end
  end

  private

  def to_s
    conf = "provider : #{@provider}\napi_key : #{@api_key}"
    message = "content: #{@content}\nphone_number: #{@phone_number}"
    "#{conf}\n#{message}"
  end

  def save_receipt(**args)
    params = @receipt_params.merge({ channel: :sms, sms_provider: @provider, sms_phone_number: @phone_number, content: @content }, args)
    Receipt.create!(params)
  end

  def handle_failure(error_message:, retry_job: true)
    save_receipt(result: :failure, error_message: error_message)

    if retry_job
      raise SmsSenderFailure, error_message
    else
      Sentry.capture_message(error_message)
    end
  end

  # These errors should not trigger a retry, because it would only fail again
  NETSIZE_PERMANENT_ERRORS = [
    15, # Message concatenation limit exceeded
    103, # Invalid account name
    117, # Invalid campaign name
  ].freeze

  # NetSize
  # `Netsize Implementation Guide, REST API - SMS.pdf`
  # returns routing errors for wrong numbers
  #
  # Utilisé par défaut pour toutes les structures (territoires) utilisant
  # RDV-Solidarités, sauf celle cité dans les autres commentaires.
  #
  def send_with_netsize
    request = Typhoeus::Request.new(
      "https://europe.ipx.com/restapi/v1/sms/send",
      method: :post,
      userpwd: @api_key,
      headers: { "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8" },
      timeout: 5,
      body: {
        destinationAddress: @phone_number,
        messageText: @content,
        originatingAddress: @sender_name,
        originatorTON: 1,
        maxConcatenatedMessages: 10,
      }
    )

    request.on_success do |response|
      parsed_response = JSON.parse(response.body)
      # parsed_response is a hash. Relevant keys are:
      # responseCode: nonzero on error. 18 is “Too low balance”, 100 is “Invalid destination address”.
      # responseMessage: error description, in english “Success” if responseCode is zero.
      # timestamp: Date & time when Netsize processed the request
      # traceId: Netsize internal identifier (for debugging purposes)
      # messageIds: Array of Netsize unique message, if the message was split. Ignored on error.
      if parsed_response["responseCode"].zero?
        save_receipt(result: :delivered, sms_count: parsed_response["messageIds"]&.count)
      else
        retry_job = !parsed_response["responseCode"].in?(NETSIZE_PERMANENT_ERRORS)
        handle_failure(error_message: "NetSize error: #{parsed_response['responseMessage']}", retry_job: retry_job)
      end
    end

    request.on_failure do |response|
      if response.timed_out?
        handle_failure(error_message: "NetSize timeout")
      elsif response.failure?
        handle_failure(error_message: "NetSize HTTP error: #{response.code}")
      end
    end

    request.run
  end

  # SFR with mail2SMS
  # /!\ does not report errors at all
  #
  # Utilisé par
  # - le département du Pas-de-Calais (62)
  # - le département des Hautes-Seine (92)
  #
  def send_with_sfr_mail2sms
    Admins::SfrMail2SmsMailer.send_sms(@api_key, @phone_number, @content).deliver_now

    save_receipt(result: :processed)
  rescue Net::SMTPServerBusy => e
    handle_failure(error_message: e.message)
  end

  # Clever Technologies
  # `Specifications API_WS_ReST Multimedias.pdf`
  # /!\ does not report routing errors for wrong numbers
  #
  # Utilisé par
  # - le département de la Seine-et-Marne (77)
  #
  def send_with_clever_technologies
    request = Typhoeus::Request.new(
      "https://webservicesmultimedias.clever-is.fr/api/pushs",
      method: :post,
      headers: { "Content-Type": "application/json; charset=UTF-8", Authorization: "Basic #{Base64.encode64(@api_key).chomp}" },
      timeout: 5,
      body: {
        datas: {
          text: @content,
          number_list: @phone_number,
          encodage: 3,
        },
      }.to_json
    )

    request.on_success do |response|
      parsed_response = JSON.parse(response.body)
      if response.code == 201
        # 201 Created on success
        # parsed_response contains a hash under the "push" key. Relevant keys are:
        # :nb_sms, :error
        save_receipt(result: :sent, sms_count: parsed_response.dig("push", "nb_sms"))
      else
        # 401 (Unauthorized) 402 (Payment Required) 430 (Account expired)
        errors = parsed_response["errors"]&.values&.join("\n")
        handle_failure(error_message: "Clever Technologies HTTP error: #{errors}")
      end
    end

    request.on_failure do |response|
      if response.timed_out?
        handle_failure(error_message: "Clever Technologies error: Timeout")
      else
        handle_failure(error_message: "Clever Technologies HTTP error: #{response.code}")
      end
    end

    request.run
  end

  # DebugLogger
  #
  def send_with_debug_logger
    message = "content: #{@content} | recipient: #{@phone_number}"
    Rails.logger.info("following SMS would have been sent in production environment: #{message}")
    Rails.logger.info("provider : #{@provider} configuration : #{@configuration}")

    save_receipt(result: :processed)
  end
end
