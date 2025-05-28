class CreateChatwootConversationJob < ApplicationJob
  queue_as :latency_30s

  def perform(first_name:, last_name:, email:, phone_number:, sujet:, message:, role:, _domain:)
    contact = ChatwootApiClient.find_or_create_contact(email:, first_name:, last_name:, phone_number:, role:)
    conversation = ChatwootApiClient.create_conversation(contact:)
    content = [sujet, message].compact.join("\n\n")
    _message = ChatwootApiClient.create_message(conversation:, content:, message_type: "outgoing", private: true)
  end
end
