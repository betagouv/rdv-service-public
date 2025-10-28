class CreateZammadTicketJob < ApplicationJob
  queue_as :latency_30s

  def perform(sender_role:, email:, phone_number:, first_name:, last_name:, subject:, body:, tags: [], user_id: nil, agent_id: nil)
    raise Error, "Les seuls sender_role valables sont usager et agent" if %w[usager agent].exclude?(sender_role.to_s)

    zammad_customer = ZammadCustomer.new(
      email:, rdvsp_role: sender_role, phone: phone_number,
      firstname: first_name, lastname: last_name
    )

    if user_id.present?
      ZammadCustomer::Augmenter.new(zammad_customer).augment_with_user(User.find(user_id))
    elsif agent_id.present?
      ZammadCustomer::Augmenter.new(zammad_customer).augment_with_agent(Agent.find(agent_id))
    else
      ZammadCustomer::Augmenter.new(zammad_customer).run
    end

    created_zammad_customer = ZammadApiClient.upsert_customer(email:, **zammad_customer.attributes)
    ZammadApiClient.create_ticket(customer_id: created_zammad_customer["id"], sender_role:, subject:, body:, tags:)
  end
end
