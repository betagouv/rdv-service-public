class CreateCrispTicketJob < ApplicationJob
  def perform(nickname:, email:, phone:, subject:, message:, role:, domain:)
    conversation = client.website.create_new_conversation(website_id)

    message = <<~MESSAGE
      #{message}

      ---
      Message envoyé depuis le formulaire de contact
    MESSAGE

    client.website.send_message_in_conversation(
      website_id,
      conversation["session_id"],
      {
        "type" => "text",
        "from" => "user",
        "origin" => ENV.fetch("CRISP_URN"), # Permet de savoir que le message provient de notre application
        "content" => message,
      }
    )

    client.website.update_conversation_metas(
      website_id,
      conversation["session_id"],
      {
        nickname:,
        email:,
        phone:,
        segments: [
          role,
          domain,
        ],
        subject:,
      }
    )
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
