class CreateChatwootConversationJob < ApplicationJob
  queue_as :latency_30s

  def perform(first_name:, last_name:, email:, phone_number:, sujet:, message:, role:, domain_id:)
    contact = ChatwootApiClient.upsert_contact(email:, first_name:, last_name:, phone_number:, role:, domain_id:)
    conversation = ChatwootApiClient.create_conversation(contact:, domain_id:)
    ChatwootApiClient.create_message(
      conversation:,
      content: [sujet, message].compact.join("\n\n"),
      message_type: "outgoing", # on aimerait plutôt créer un message incoming mais c’est impossible
      private: true
    )
    Users::DemandesSupportMailer
      .with(
        subject: conversation.mail_subject,
        in_reply_to: conversation.mail_reference, # ce header indique aux clients mail de grouper les mails
        email:,
        domain_id:,
        demande_support_sujet: sujet,
        demande_support_message: message
      )
      .conversation_created
      .deliver_later
  end
end
