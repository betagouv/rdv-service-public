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
  def self.create_ticket(sender_role:, subject:, email:, body:, tags: [])
    group = { usager: "Users", agent: "Agents" }[sender_role]
    raise Error, "Les seuls sender_role valables sont :usager et :agent" if group.nil?

    params = {
      group:,
      title: subject,
      customer_id: "guess:#{email}",
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

  def self.search_tickets(condition:, query: nil)
    connection.post("api/v1/tickets/search?#{query}", { condition: }).body
  end

  def self.count_tickets(condition:)
    params = { condition: }
    response_data = connection.post("api/v1/tickets/search?only_total_count=1", params).body
    response_data.fetch("total_count")
  end

  def self.count_new_tickets
    count_tickets(
      condition: {
        "ticket.state_id": { operator: "is", value: ["1"] }, # 1 = new = aucune réponse n’a été envoyée
      }
    )
  end

  def self.count_open_tickets(owner_id:)
    count_tickets(
      condition: {
        "ticket.state_id": { operator: "is", value: %w[2] }, # 2 = open = une première réponse a déjà été envoyée
        "ticket.owner_id": { operator: "is", value: [owner_id] },
      }
    )
  end

  def self.search_assigned_tickets
    search_tickets(
      condition: {
        "ticket.state_id": { operator: "is", value: [1, 2] }, # new or open
        "ticket.owner_id": { operator: "is not", value: [1] },
      },
      query: "per_page=200&expand=true" # 200 seems to be the max
    ).map { Ticket.new(_1) }
  end

  def self.search_unassigned_tickets
    search_tickets(
      condition: {
        "ticket.state_id": { operator: "is", value: [1, 2] }, # new or open
        "ticket.owner_id": { operator: "is", value: [1] },
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
        instance_variable_set(:"@#{attr}", raw_ticket.fetch(attr.to_s))
      end
    end

    def last_contact_customer_at
      @raw_ticket["last_contact_customer_at"] &&
        Time.zone.parse(@raw_ticket["last_contact_customer_at"])
    end

    def awaiting_response_since
      @awaiting_response_since ||= last_contact_customer_at ||
                                   Time.zone.parse(@raw_ticket["created_at"])
    end
  end
end
