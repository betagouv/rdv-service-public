class CreateZammadTicketJob < ApplicationJob
  def perform(sender_role:, email:, subject:, body:, tags: [])
    ZammadApiClient.create_ticket(sender_role:, email:, subject:, body:, tags:)
  end
end
