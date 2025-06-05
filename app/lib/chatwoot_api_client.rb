class ChatwootApiClient
  class Error < StandardError; end

  ACCOUNT_ID = "1".freeze
  INBOXES_IDS = {
    "RDV_SOLIDARITES" => 6,    # inbox RDVS
    "RDV_AIDE_NUMERIQUE" => 1, # inbox RDVSP
    "RDV_MAIRIE" => 1, # inbox RDVSP
  }.freeze

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

  def self.upsert_contact(email:, domain_id:, phone_number: nil, first_name: nil, last_name: nil, role: nil)
    existing_contact_by_email = find_contact_by_email(email)
    existing_contact_by_phone_number = find_contact_by_phone_number(phone_number)

    if existing_contact_by_email &&
       existing_contact_by_phone_number &&
       existing_contact_by_phone_number["id"] != existing_contact_by_email["id"]
      update_contact(existing_contact_by_phone_number, phone_number: nil)
      existing_contact_by_phone_number = nil
    end

    existing_contact = [existing_contact_by_email, existing_contact_by_phone_number].compact.first
    # Le cas ci-dessous est mal géré :(
    # Il s’agit du cas où un contact nous a écrit via mail sur RDVS puis nous écrit sur RDVSP
    #
    # - si on supprime le contact existants, ses conversations sont aussi supprimées
    # - si on essaie de libérer son email et son num de tel comme ci-dessous,
    # le contact_inbox.source_id de ce contact reste sur l’ancien email 😭
    #
    # if existing_contact && existing_contact["contact_inboxes"].none? { _1.dig("inbox", "id") == inbox_id }
    # update_contact(
    #   existing_contact,
    #   email: "archived+#{existing_contact['id']}@email.com",
    #   phone_number: nil,
    #   custom_attributes: { archived_details: existing_contact.values_at("email", "phone_number").compact_blank.join(",") }
    # )
    # existing_contact = nil
    # end

    if existing_contact
      update_contact(existing_contact, email:, phone_number:, first_name:, last_name:, role:)
    else
      create_contact(email:, phone_number:, first_name:, last_name:, role:, domain_id:)
    end
  end

  def self.find_contact_by_email(email)
    search_contacts(query: email).find { _1["email"] == email }
  end

  def self.find_contact_by_phone_number(phone_number_raw)
    return nil if phone_number_raw.blank?

    phone_number_parsed = Phonelib.parse(phone_number_raw)
    if phone_number_parsed.valid?
      search_contacts(query: phone_number_parsed.to_s)
        .find { _1["phone_number"] == phone_number_parsed.to_s }
    end
  end

  def self.search_contacts(query:)
    # cf https://developers.chatwoot.com/api-reference/contacts/search-contacts
    res = connection.get("api/v1/accounts/#{ACCOUNT_ID}/contacts/search", { q: query })
    res.body.dig("meta", "count") < 1 ? [] : res.body["payload"]
  end

  # cet endpoint a été trouvé par tatonnement, mais il n’y a pas d’équivalent en post
  # je cherchais un moyen de créer un deuxième contact_inbox différent du premier mais impossible
  # contexte : email déjà utilisé sur une inbox 1 et maintenant sur l’inbox 2
  #
  # def self.find_contact_inboxes(contact:)
  #   res = connection.get("api/v1/accounts/#{ACCOUNT_ID}/contacts/#{contact['id']}/contactable_inboxes")
  #   res.body
  # end

  def self.create_contact(email:, domain_id:, **attributes)
    # cf https://developers.chatwoot.com/api-reference/contacts/create-contact
    params = create_or_update_params_from_attributes(email:, **attributes)
    params.merge!(inbox_id: INBOXES_IDS.fetch(domain_id))
    res = connection.post("api/v1/accounts/#{ACCOUNT_ID}/contacts", params)
    res.body.dig("payload", "contact")
  end

  def self.update_contact(existing_contact, **attributes)
    # cf https://developers.chatwoot.com/api-reference/contacts/create-contact
    params = create_or_update_params_from_attributes(**attributes)
    if attributes.key?(:phone_number) && attributes[:phone_number].blank?
      params[:phone_number] = nil # mark the phone number for deletion
    end
    res = connection.put("api/v1/accounts/#{ACCOUNT_ID}/contacts/#{existing_contact['id']}", params)
    res.body["payload"]
  end

  def self.create_or_update_params_from_attributes(email: nil, phone_number: nil, first_name: nil, last_name: nil, role: nil, custom_attributes: {})
    params = { custom_attributes: }
    params[:email] = email if email.present?
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
    params
  end

  def self.create_conversation(contact:, domain_id:)
    # https://developers.chatwoot.com/api-reference/conversations/create-new-conversation
    inbox_id = INBOXES_IDS.fetch(domain_id)
    # NOTE: ici on utilise directement l’email comme source_id car c’est toujours ça qui est utilisé
    # pour le cas où un contact nous a écrit sur RDVS puis nous écrit sur RDVSP
    # ça permettra de ne pas exploser mais de l’orienter vers la mauvaise inbox 🤷
    source_id = contact["email"]
    # source_id = existing_contact["contact_inboxes"].find { _1.dig("inbox", "id") == inbox_id }
    res = connection.post("api/v1/accounts/#{ACCOUNT_ID}/conversations", inbox_id:, source_id:)
    res.body
  end

  # def self.delete_test_contacts(query:, dry_run: true)
  #   search_contacts(query:).each do |contact|
  #     Rails.logger.info "#{dry_run ? 'would delete contact' : 'deleting contact'} #{contact['email']}…"
  #     delete_contact(contact) unless dry_run
  #     Rails.logger.info "done!"
  #   end
  # end
  #
  # def self.delete_contact(contact)
  #   connection.delete("api/v1/accounts/#{ACCOUNT_ID}/contacts/#{contact['id']}")
  # end

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
