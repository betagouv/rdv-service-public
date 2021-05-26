# frozen_string_literal: true

class Admin::StaticPagesController < AgentAuthController
  def support
    skip_authorization
    @support_ticket_form = SupportTicketForm.new(
      first_name: current_agent.first_name,
      last_name: current_agent.last_name,
      email: current_agent.email,
      departement: current_organisation.departement_number
    )
  end
end
