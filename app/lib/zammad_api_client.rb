class ZammadApiClient
  class Error < StandardError; end

  def self.connection
    Faraday.new(
      url: "https://zammad10.ethibox.fr/".freeze,
      headers: { Authorization: "Token token=#{ENV['ZAMMAD_API_TOKEN']}" }
    ) do |builder|
      builder.request :json
      builder.response :json
      builder.response :raise_error # raise an error on 4xx and 5xx responses
    end
  end

  def self.create_ticket(sender_role:, subject:, email:, body:)
    group = { usager: "Users", agent: "Agents" }[sender_role]
    raise Error, "Les seuls sender_role valables sont :usager et :agent" if group.nil?

    params = {
      group:,
      title: subject,
      customer_id: "guess:#{email}",
      article: { subject:, body:, type: "web", sender: "Customer" },
    }
    response_data = connection.post("api/v1/tickets", params).body

    Ticket.new(response_data)
  rescue Faraday::Error => e
    Rails.logger.error "Erreur lors de l’appel API pour créer un ticket Zammad : statut HTTP #{e.response[:status]} - #{e.response[:body]}"
    raise e
  end

  class Ticket
    ATTRIBUTES = %i[id number title customer_id].freeze
    attr_reader(*ATTRIBUTES)

    def initialize(raw_ticket)
      ATTRIBUTES.each do |attr|
        instance_variable_set(:"@#{attr}", raw_ticket.fetch(attr.to_s))
      end
    end
  end
end
