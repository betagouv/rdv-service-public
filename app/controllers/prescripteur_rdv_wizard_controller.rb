# frozen_string_literal: true

class PrescripteurRdvWizardController < ApplicationController
  include SearchContextHelper

  before_action do
    @step_titles = ["Choix du rendez-vous", "Prescripteur", "Bénéficiaire", "Confirmation"]
  end

  before_action :check_rdv_wizard_attributes, except: %i[start confirmation]
  before_action :set_rdv_wizard,                  only: %i[new_prescripteur new_beneficiaire create_rdv]
  before_action :redirect_if_creneau_unavailable, only: %i[new_prescripteur new_beneficiaire create_rdv]

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
  end

  def create_rdv
    beneficiaire_params = params.require(:beneficiaire_form).permit(*BeneficiaireForm::ATTRIBUTES)

    @beneficiaire = BeneficiaireForm.new(beneficiaire_params)

    if @beneficiaire.valid?
      session[:rdv_wizard_attributes][:user] = beneficiaire_params

      rdv_wizard = PrescripteurRdvWizard.new(session[:rdv_wizard_attributes], current_domain)
      rdv_wizard.create!

      session[:prescripteur_id] = rdv_wizard.prescripteur.id

      session.delete(:rdv_wizard_attributes)
      redirect_to prescripteur_confirmation_path
    else
      @step_title = @step_titles[2]
      render :new_beneficiaire
    end
  end

  def confirmation
    @step_title = @step_titles[3]
    @prescripteur = Prescripteur.find(session[:prescripteur_id])
  end

  private

  def check_rdv_wizard_attributes
    if session[:rdv_wizard_attributes].blank?
      Sentry.capture_message("Prescripteur sans infos de creneau. Voir https://github.com/betagouv/rdv-solidarites.fr/issues/3420")
      flash[:error] = "Nous n'avons pas trouvé le créneau pour lequel vous souhaitiez prendre rendez-vous."
      redirect_to prendre_rdv_path(prescripteur: 1) and return
    end
  end

  def set_rdv_wizard
    @rdv_wizard = PrescripteurRdvWizard.new(session[:rdv_wizard_attributes], current_domain)
  end

  def redirect_if_creneau_unavailable
    if @rdv_wizard.creneau.nil?
      flash[:error] = "Ce créneau n'est plus disponible. Veuillez en choisir un autre."
      redirect_to path_to_creneau_selection(@rdv_wizard.params_to_selections)
    end
  end
end
