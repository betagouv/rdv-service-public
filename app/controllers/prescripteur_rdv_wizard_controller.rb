# frozen_string_literal: true

class PrescripteurRdvWizardController < ApplicationController
  before_action do
    @step_titles = ["Choix du rendez-vous", "Prescripteur", "Bénéficiaire", "Confirmation"]
  end

  def start
    session[:rdv_wizard_attributes] = params.permit(
      *Users::RdvWizardStepsController::RDV_PERMITTED_PARAMS,
      *Users::RdvWizardStepsController::EXTRA_PERMITTED_PARAMS
    )

    redirect_to prescripteur_new_prescripteur_path
  end

  def new_prescripteur
    @step_title = @step_titles[1]

    @prescripteur = Prescripteur.new(session[:autocomplete_prescripteur_attributes])

    @rdv_wizard = PrescripteurRdvWizard.new(session[:rdv_wizard_attributes], current_domain)
  end

  def save_prescripteur
    prescripteur_attributes = params[:prescripteur].permit(:first_name, :last_name, :email, :phone_number)

    session[:autocomplete_prescripteur_attributes] = prescripteur_attributes

    session[:rdv_wizard_attributes][:prescripteur] = prescripteur_attributes

    redirect_to prescripteur_new_beneficiaire_path
  end

  def new_beneficiaire
    @step_title = @step_titles[2]

    @beneficiaire = BeneficiaireForm.new

    @rdv_wizard = PrescripteurRdvWizard.new(session[:rdv_wizard_attributes], current_domain)
  end

  def create_rdv
    beneficiaire_params = params.require(:beneficiaire_form).permit(*BeneficiaireForm::ATTRIBUTES)

    @beneficiaire = BeneficiaireForm.new(beneficiaire_params)

    if @beneficiaire.valid?
      session[:rdv_wizard_attributes][:user] = beneficiaire_params

      rdv_wizard = PrescripteurRdvWizard.new(session[:rdv_wizard_attributes], current_domain)
      rdv_wizard.create_rdv!

      redirect_to prescripteur_confirmation_path
    else
      @step_title = @step_titles[2]
      @rdv_wizard = PrescripteurRdvWizard.new(session[:rdv_wizard_attributes], current_domain)
      render :new_beneficiaire
    end
  end

  def confirmation
    @step_title = @step_titles[3]
  end
end
