class StaticPagesController < ApplicationController
  def mds; end

  def contact
    @support_ticket_form = SupportTicketForm.new(
      first_name: current_user&.first_name,
      last_name: current_user&.last_name,
      email: current_user&.email
    )
  end

  def admin_support
    @support_ticket_form = SupportTicketForm.new(
      first_name: current_agent.first_name,
      last_name: current_agent.last_name,
      email: current_agent.email,
      departement: current_organisation.departement
    )
  end
end
