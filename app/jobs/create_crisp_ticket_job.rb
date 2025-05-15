class CreateCrispTicketJob < ApplicationJob
  queue_as :latency_30s

  def perform(nickname:, email:, phone:, subject:, message:, role:, domain:)
    # On ne crée pas de ticket si l’email n’a pas un format correct
    # Placé ici suite à un problème de spam, il faudra à terme remonter cette validation dans le formulaire
    return unless email =~ URI::MailTo::EMAIL_REGEXP
    # Nous avons ajouté la ligne suivante suite à du spam
    # On laisse cette ligne en attendant d’avoir un système de captcha
    return if email =~ /.*@example\.com$/

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
        device: {
          locales: ["fr"],
        },
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
