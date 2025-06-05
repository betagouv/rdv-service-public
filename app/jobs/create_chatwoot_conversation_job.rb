class CreateChatwootConversationJob < ApplicationJob
  queue_as :latency_30s

  def perform(first_name:, last_name:, email:, phone_number:, sujet:, message:, role:, domain:)
    contact = ChatwootApiClient.upsert_contact(email:, first_name:, last_name:, phone_number:, role:)
    conversation = ChatwootApiClient.create_conversation(contact:)
    content = [sujet, message].compact.join("\n\n")
    _message = ChatwootApiClient.create_message(conversation:, content:, message_type: "outgoing", private: true)
    Users::DemandesSupportMailer.with(conversation_id: conversation["id"], email:, domain:, sujet:, message:).conversation_created.deliver_later
  end
end
