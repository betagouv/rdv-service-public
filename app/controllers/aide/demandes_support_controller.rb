class Aide::DemandesSupportController < ApplicationController
  def new
    form_params = { current_domain: }
    if current_user.present?
      form_params[:role] = :usager
      form_params[:first_name] = current_user.first_name
      form_params[:last_name] = current_user.last_name
      form_params[:email] = current_user.email
      form_params[:phone_number] = current_user.phone_number
    elsif current_agent.present?
      form_params[:role] = :agent
      form_params[:first_name] = current_agent.first_name
      form_params[:last_name] = current_agent.last_name
      form_params[:email] = current_agent.email
    end
    DemandeSupportForm::ATTRIBUTES.each do |attr|
      form_params[attr] = params[attr] if params[attr].present?
      # on récupère volontairement les valeurs passées en params GET après l’autocomplétion depuis la session
    end
    @form = DemandeSupportForm.new(**form_params)
  end

  def create
    demande_params = params
      .require(:demande_support_form)
      .permit(:sujet, :email, :first_name, :last_name, :phone_number, :message)
      .to_h
      .symbolize_keys

    # pour éviter un faux positif brakeman
    demande_params[:role] = :agent if params[:demande_support_form][:role] == "agent"
    demande_params[:role] = :usager if params[:demande_support_form][:role] == "usage"

    @form = DemandeSupportForm.new(**demande_params, current_domain:)
    if @form.submit
      redirect_to(
        @form.role_usager? ? aide_documentation_usager_path : root_path,
        flash: { success: "Votre demande de support a bien été envoyée, nous essaierons de vous répondre au plus vite par email ou par téléphone" }
      )
    else
      render :new
    end
  end
end
