class CreateZammadTicketJob < ApplicationJob
  queue_as :latency_30s

  def perform(sender_role:, email:, phone_number:, first_name:, last_name:, subject:, body:, tags: [], user_id: nil, agent_id: nil)
    raise Error, "Les seuls sender_role valables sont usager et agent" if %w[usager agent].exclude?(sender_role.to_s)

    customer_attributes = ZammadCustomer::Attributes.new(
      email:, rdvsp_role: sender_role, phone: phone_number,
      firstname: first_name, lastname: last_name
    )

    if user_id.present?
      customer_attributes.augment_with(ZammadCustomer::UserAugmenter.new(record: User.find(user_id)))
    elsif agent_id.present?
      customer_attributes.augment_with(ZammadCustomer::AgentAugmenter.new(record: Agent.find(agent_id)))
    else
      customer_attributes.find_user_or_agent_and_augment
    end

    zammad_customer = ZammadApiClient.upsert_customer(email:, **customer_attributes.to_h)
    ZammadApiClient.create_ticket(customer_id: zammad_customer["id"], sender_role:, subject:, body:, tags:)
  end
end
