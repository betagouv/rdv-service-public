class CreateCrispTicketJob < ApplicationJob
  def perform(nickname:, email:, phone:, subject:, message:, role:, domain:)
    response = client.website.create_new_conversation(website_id)

    message = <<~MESSAGE
      #{message}

      ---
      Message envoyé depuis le formulaire de contact
    MESSAGE

    query = {
      "type" => "text",
      "from" => "user",
      "origin" => ENV.fetch("CRISP_URN"), # Permet de savoir que le message provient de notre application
      "content" => message,
    }

    client.website.send_message_in_conversation(website_id, response["session_id"], query)

    data = {
      nickname:,
      email:,
      phone:,
      segments: [
        role,
        domain,
      ],
      subject:,
    }

    client.website.update_conversation_metas(website_id, response["session_id"], data)
  end

  private

  def client
    @client ||= begin
      client = Crisp::Client.new
      client.set_tier("plugin")
      client.authenticate(ENV.fetch("CRISP_IDENTIFIER"), ENV.fetch("CRISP_KEY"))
      client
    end
  end

  def website_id
    ENV.fetch("CRISP_WEBSITE_ID")
  end
end
