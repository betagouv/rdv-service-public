class PrescripteurRdvWizardController < ApplicationController
  include SearchContextHelper

  before_action :log_session_to_sentry
  before_action :check_rdv_wizard_attributes, except: %i[start confirmation cancel_rdv show]
  before_action :set_rdv_wizard, only: %i[new_prescripteur new_beneficiaire create_rdv]
  before_action :set_prescripteur_from_session, only: %i[confirmation cancel_rdv]
  before_action :redirect_if_creneau_unavailable, only: %i[new_prescripteur new_beneficiaire create_rdv]
  before_action :set_paper_trail_whodunnit

  def start
    session[:rdv_wizard_attributes] = params.permit(
      *Users::RdvWizardStepsController::RDV_PERMITTED_PARAMS,
      *Users::RdvWizardStepsController::EXTRA_PERMITTED_PARAMS
    )

    redirect_to prescripteur_new_prescripteur_path
  end

  def new_prescripteur
    @prescripteur = Prescripteur.new(session[:autocomplete_prescripteur_attributes])
  end

  def store_prescripteur_in_session
    prescripteur_attributes = params[:prescripteur].permit(:first_name, :last_name, :email, :phone_number)

    @prescripteur = Prescripteur.new(prescripteur_attributes)

    @prescripteur.validate
    # On veut valider uniquement les attributs qui sont sur le formulaire, pas l'association avec le Participation
    valid_prescripteur_form = prescripteur_attributes.keys.none? { |key| @prescripteur.errors[key].present? }

    if valid_prescripteur_form
      session[:autocomplete_prescripteur_attributes] = prescripteur_attributes

      session[:rdv_wizard_attributes][:prescripteur] = prescripteur_attributes

      redirect_to prescripteur_new_beneficiaire_path
    else
      flash[:error] = "Veuillez compléter tous les champs obligatoires"

      render :new_prescripteur
    end
  end

  def new_beneficiaire
    @beneficiaire = BeneficiaireForm.new
  end

  def create_rdv
    beneficiaire_params = params.require(:beneficiaire_form).permit(*BeneficiaireForm::ATTRIBUTES)

    @beneficiaire = BeneficiaireForm.new(beneficiaire_params.merge(motif_id: session[:rdv_wizard_attributes]["motif_id"]))

    if @beneficiaire.valid?
      session[:rdv_wizard_attributes][:user] = beneficiaire_params.except("ants_meeting_point_id")

      rdv_wizard = PrescripteurRdvWizard.new(session[:rdv_wizard_attributes], current_domain)
      rdv_wizard.create!

      session[:prescripteur_id] = rdv_wizard.prescripteur.id

      session.delete(:rdv_wizard_attributes)
      redirect_to prescripteur_confirmation_path
    else
      render :new_beneficiaire
    end
  end

  def cancel_rdv
    if @prescripteur.rdv.cancellable_by_user?
      @prescripteur.rdv.update_and_notify(@prescripteur, status: "excused")
      flash[:success] = "Le rendez-vous a bien été annulé."
    else
      flash[:error] = "Le rendez-vous ne peut plus être annulé."
    end

    redirect_to prescripteur_show_path
  end

  def confirmation
    render locals: { prescripteur: @prescripteur }
  end

  def show
    if params[:token].present?
      prescripteur = Prescripteur.find_by(token: params[:token])
      session[:prescripteur_id] = prescripteur.id
    else
      prescripteur = Prescripteur.find(session[:prescripteur_id])
    end

    render locals: { prescripteur: }
  end

  private

  def log_session_to_sentry
    Sentry.add_breadcrumb(Sentry::Breadcrumb.new(message: "Session", data: session.to_h.slice("rdv_wizard_attributes", "autocomplete_prescripteur_attributes")))
  end

  def check_rdv_wizard_attributes
    if session[:rdv_wizard_attributes].blank?
      Sentry.capture_message("Prescripteur sans infos de creneau. Voir https://github.com/betagouv/rdv-solidarites.fr/issues/3420", fingerprint: ["presc_sans_creneau"])
      flash[:error] = "Nous n'avons pas trouvé le créneau pour lequel vous souhaitiez prendre rendez-vous."
      redirect_to prendre_rdv_path(prescripteur: 1)
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

  def set_prescripteur_from_session
    @prescripteur = Prescripteur.find(session[:prescripteur_id])
  end

  def user_for_paper_trail
    if @rdv_wizard&.prescripteur
      @rdv_wizard.prescripteur.name_for_paper_trail
    elsif @prescripteur
      @prescripteur.name_for_paper_trail
    end
  end
end
