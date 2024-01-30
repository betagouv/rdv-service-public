class Admin::PrescriptionController < AgentAuthController
  include GeoCoding

  before_action :set_search_context, only: %i[search_creneau]
  before_action :set_rdv_wizard, only: %i[user_selection recapitulatif create_rdv]
  before_action :redirect_if_creneau_gone, only: %i[user_selection recapitulatif create_rdv]

  def search_creneau
    skip_authorization
    session[:agent_prescripteur_organisation_id] = params[:organisation_id]
  end

  def user_selection
    skip_authorization
  end

  def recapitulatif
    authorize(user, :show?)
    authorize(@rdv_wizard.rdv.motif, :bookable?)
  end

  def create_rdv
    # TODO: Autoriser sur la participation (vérifier que le current_agent accéde au user et au motif)
    authorize(user, :show?)
    authorize(@rdv_wizard.rdv.motif, :bookable?)

    @rdv_wizard.create!
    redirect_to confirmation_admin_organisation_prescription_path(participation_id: @rdv_wizard.participation.id)
  end

  def confirmation
    participation = Participation.find(params[:participation_id])
    @rdv = participation.rdv
    authorize(participation, :show?)
  end

  private

  def set_search_context
    @context = AgentPrescriptionSearchContext.new(user: user, query_params: augmented_params, current_organisation: current_organisation)
  end

  def set_rdv_wizard
    @rdv_wizard = AgentPrescripteurRdvWizard.new(agent: current_agent, query_params: wizard_params, current_domain: current_domain)
  end

  def redirect_if_creneau_gone
    unless @rdv_wizard.creneau
      flash[:error] = "Ce créneau n'est plus disponible. Veuillez en sélectionner un autre."
      redirect_to(search_creneau_admin_organisation_prescription_path(params[:organisation_id], @rdv_wizard.params_to_selections))
    end
  end

  def augmented_params
    params = search_context_params.merge(prescripteur: true)

    if user
      geolocation_results = get_geolocation_results(user.address, params[:departement])
    end

    if geolocation_results.present?
      params.merge!(
        city_code: geolocation_results[:city_code],
        street_ban_id: geolocation_results[:street_ban_id]
      )
    end

    params
  end

  def search_context_params
    params.permit(AgentPrescriptionSearchContext::STRONG_PARAMS_LIST)
  end

  def wizard_params
    # Ces paramètres permettent de passer du choix de creneau au wizard (create et récapitulatif)
    params.permit(%i[starts_at rdv_collectif_id] + AgentPrescriptionSearchContext::STRONG_PARAMS_LIST)
  end

  def user
    return if params[:user_ids].blank?

    @user ||= policy_scope(User, policy_scope_class: Agent::UserPolicy::Scope).find_by_id(params[:user_ids].first)
  end
end
