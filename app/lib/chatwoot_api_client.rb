class ChatwootApiClient
  class Error < StandardError; end

  ACCOUNT_ID = "1".freeze
  INBOX_ID = "1".freeze # l’ID de la boîte de réception email

  def self.connection
    @connection ||= Faraday.new(
      url: "https://chatwoot5.ethibox.fr/".freeze,
      headers: { api_access_token: ENV["CHATWOOT_API_TOKEN"] }
    ) do |builder|
      builder.request :json
      builder.response :json
      builder.response :raise_error # raise an error on 4xx and 5xx responses
      # builder.response :logger, ::Logger.new(STDOUT), bodies: true
    end
  end

  def self.find_or_create_contact(email:, phone_number: nil, first_name: nil, last_name: nil, role: nil)
    # TODO: update existing
    find_contact(email:) || create_contact(email:, phone_number:, first_name:, last_name:, role:)
  end

  def self.find_contact(email:)
    # TODO: find by phone_number because it’s unique
    # cf https://developers.chatwoot.com/api-reference/contacts/search-contacts
    res = connection.get("api/v1/accounts/#{ACCOUNT_ID}/contacts/search", { q: email })
    if res.body.dig("meta", "count") < 1
      nil
    else
      res.body["payload"].find { _1["email"] == email }
    end
  end

  def self.create_contact(email:, phone_number: nil, first_name: nil, last_name: nil, role: nil)
    # cf https://developers.chatwoot.com/api-reference/contacts/create-contact
    params = { inbox_id: INBOX_ID, email:, custom_attributes: {} }
    if phone_number.present?
      phone_number_parsed = Phonelib.parse(phone_number)
      if phone_number_parsed.valid?
        params[:phone_number] = phone_number_parsed.to_s
      else
        params[:custom_attributes][:invalid_phone_number] = phone_number
      end
    end
    params[:name] = [first_name, last_name].compact.join(" ") if first_name.present? || last_name.present?
    params[:custom_attributes][:role] = role if role.present?
    res = connection.post("api/v1/accounts/#{ACCOUNT_ID}/contacts", params)
    res.body.dig("payload", "contact")
  end

  def self.create_conversation(contact:)
    # https://developers.chatwoot.com/api-reference/conversations/create-new-conversation
    source_id = contact["contact_inboxes"].find { _1.dig("inbox", "id")&.to_s == INBOX_ID }["source_id"]
    res = connection.post("api/v1/accounts/#{ACCOUNT_ID}/conversations", inbox_id: INBOX_ID, source_id:)
    res.body
  end

  def self.create_message(conversation:, content:, message_type:, private:)
    raise ArgumentError, "message_type must be outgoing or incoming" if %w[outgoing incoming].exclude?(message_type)

    # https://developers.chatwoot.com/api-reference/conversations/create-new-message
    res = connection.post(
      "api/v1/accounts/#{ACCOUNT_ID}/conversations/#{conversation['id']}/messages",
      message_type:,
      private:,
      content:
    )
    res.body
  end
end
