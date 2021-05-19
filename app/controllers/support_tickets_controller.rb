# frozen_string_literal: true

class SupportTicketsController < ApplicationController
  def create
    @support_ticket_form = SupportTicketForm.new(contact_params.to_h)
    if @support_ticket_form.save
      redirect_to contact_path(anchor: ""), flash: { success: "Votre demande a bien été reçue, nous vous répondrons rapidement par mail" }
    else
      render "static_pages/contact"
    end
  end

  private

  def contact_params
    params.require(:support_ticket).permit(:subject, :first_name, :last_name, :email, :message, :departement, :city)
  end
end
