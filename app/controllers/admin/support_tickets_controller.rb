# frozen_string_literal: true

class Admin::SupportTicketsController < AgentAuthController
  def create
    @support_ticket_form = SupportTicketForm.new(
      first_name: current_agent.first_name,
      last_name: current_agent.last_name,
      email: current_agent.email,
      departement: current_organisation.departement_number,
      **support_ticket_params
    )
    authorize(@support_ticket_form, policy_class: Agent::SupportTicketPolicy)
    if @support_ticket_form.save
      redirect_to admin_organisation_support_path(current_organisation), flash: { success: "Votre demande a bien été reçue, nous vous répondrons rapidement par mail" }
    else
      render "admin/static_pages/support"
    end
  end

  private

  def support_ticket_params
    params.require(:support_ticket).permit(:subject, :message)
  end
end
