class CreateZammadTicketJob < ApplicationJob
  attr_reader :sender_role, :email, :phone_number, :first_name, :last_name, :user_id, :agent_id

  queue_as :latency_30s

  def perform(sender_role:, email:, phone_number:, first_name:, last_name:, subject:, body:, tags: [], user_id: nil, agent_id: nil)
    @sender_role = sender_role
    @email = email
    @phone_number = phone_number
    @first_name = first_name
    @last_name = last_name
    @user_id = user_id
    @agent_id = agent_id
    zammad_customer = ZammadApiClient.upsert_customer(email:, **zammad_customer_attributes)
    ZammadApiClient.create_ticket(customer_id: zammad_customer["id"], sender_role:, subject:, body:, tags:)
  end

  private

  def zammad_customer_attributes
    raise Error, "Les seuls sender_role valables sont usager et agent" if %w[usager agent].exclude?(sender_role.to_s)

    {
      firstname: first_name,
      lastname: last_name,
      phone: phone_number,
      rdvsp_role: sender_role,
      **zammad_customer_builder.attributes,
    }.compact
  end

  def zammad_customer_builder
    if user_id.present?
      ZammadCustomer::UserBuilder.new(record: User.find(user_id))
    elsif agent_id.present?
      ZammadCustomer::AgentBuilder.new(record: Agent.find(agent_id))
    else
      ZammadCustomer.user_or_agent_builder(email:, phone_number:)
    end
  end
end
