class DemandesSupportController < ApplicationController
  def new
    params.require(%i[role])
    @form = DemandeSupportForm.new(role: params[:role], sujet: params[:sujet], current_domain:)
  end

  def create
    demande_params = params
      .require(:demande_support_form)
      .permit(:role, :sujet, :email, :first_name, :last_name, :phone, :message)
    @form = DemandeSupportForm.new(**demande_params.to_h.symbolize_keys, current_domain:)
    if @form.submit
      redirect_to aide_usager_path, flash: { success: "Votre demande de support a bien été envoyée, nous essaierons de vous répondre au plus vite par email ou par téléphone" }
    else
      render :new
    end
  end
end
