class ZammadApiClient
  class Error < StandardError; end

  def self.connection
    @connection ||= Faraday.new(
      url: "https://zammad10.ethibox.fr/".freeze,
      headers: { Authorization: "Token token=#{ENV['ZAMMAD_API_TOKEN']}" }
    ) do |builder|
      builder.request :json
      builder.response :json
      builder.response :raise_error # raise an error on 4xx and 5xx responses
    end
  end

  # cf https://docs.zammad.org/en/latest/api/ticket/index.html#create
  def self.create_ticket(sender_role:, customer_id:, subject:, body:, tags: [])
    group = { usager: "Users", agent: "Agents" }.with_indifferent_access[sender_role]
    raise Error, "Les seuls sender_role valables sont :usager et :agent" if group.nil?

    params = {
      group:,
      title: subject,
      customer_id:,
      article: { subject:, body:, type: "web", sender: "Customer" },
    }
    response_data = connection.post("api/v1/tickets", params).body

    ticket = Ticket.new(response_data)

    tags.each do |tag|
      connection.post("api/v1/tags/add", { item: tag, object: "Ticket", o_id: ticket.id })
    end

    ticket
  rescue Faraday::Error => e
    Rails.logger.error "Erreur lors de l’appel API pour créer un ticket Zammad : statut HTTP #{e.response[:status]} - #{e.response[:body]}"
    raise e
  end

  def self.upsert_user(email:, sender_role:, first_name:, last_name:, phone_number:)
    role = { usager: "Customer", agent: "Usager Agent" }.with_indifferent_access[sender_role]
    raise Error, "Les seuls sender_role valables sont :usager et :agent" if role.nil?

    base_attributes = { firstname: first_name, lastname: last_name, phone: phone_number }
    existing_user = connection.get("api/v1/users/search", condition: { "user.email": { operator: "is", value: email } }).body.first
    if existing_user
      return existing_user if existing_user.symbolize_keys.slice(*base_attributes.keys) == base_attributes

      connection.put("api/v1/users/#{existing_user['id']}", base_attributes).body
    else
      role = { user: "Customer", agent: "Usager Agent" }.fetch(sender_role.to_sym)
      params = base_attributes.merge(email:, roles: [role])
      connection.post("api/v1/users", params).body
    end
  rescue Faraday::Error => e
    Rails.logger.error "Erreur lors d’un appel API à Zammad : statut HTTP #{e.response[:status]} - #{e.response[:body]}"
    raise e
  end

  def self.search_tickets(condition:, query: nil)
    connection.post("api/v1/tickets/search?#{query}", { condition: }).body
  end

  def self.search_new_and_open_tickets
    search_tickets(
      condition: {
        "ticket.state_id": { operator: "is", value: [1, 2] }, # new or open
      },
      query: "per_page=200&expand=true" # 200 seems to be the max
    ).map { Ticket.new(_1) }
  end

  class Ticket
    ATTRIBUTES = %i[id number title customer_id owner owner_id].freeze
    attr_reader(*ATTRIBUTES)

    def initialize(raw_ticket)
      @raw_ticket = raw_ticket
      ATTRIBUTES.each do |attr|
        instance_variable_set(:"@#{attr}", raw_ticket[attr.to_s])
      end
    end

    def last_contact_customer_at
      return nil if @raw_ticket["last_contact_customer_at"].blank?

      Time.zone.parse(@raw_ticket["last_contact_customer_at"])
    end

    def created_at
      Time.zone.parse(@raw_ticket["created_at"])
    end

    def awaiting_response_since
      @awaiting_response_since ||= last_contact_customer_at || created_at
    end
  end
end
