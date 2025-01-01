class DemandesSupportController < ApplicationController
  def new
    params.require(%i[role])
    @form = DemandeSupportForm.new(role: params[:role], sujet: params[:sujet], current_domain:)
  end

  def create
    demande_params = params
      .require(:demande_support_form)
      .permit(:role, :sujet, :email, :first_name, :last_name, :phone, :message)
    @form = DemandeSupportForm.new(**demande_params, current_domain:)
    render :new
  end
end
