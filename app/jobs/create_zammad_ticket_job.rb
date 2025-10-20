class CreateZammadTicketJob < ApplicationJob
  queue_as :latency_30s

  def perform(sender_role:, email:, phone_number:, first_name:, last_name:, subject:, body:, tags: [])
    zammad_customer = ZammadApiClient.upsert_user(email:, sender_role:, phone_number:, first_name:, last_name:)
    ZammadApiClient.create_ticket(customer_id: zammad_customer["id"], sender_role:, subject:, body:, tags:)
  end
end
