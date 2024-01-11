class Admin::PrescriptionController < AgentAuthController
  include GeoCoding

  def search_creneau
    authorize(user, :show?)
    @context = AgentPrescriptionSearchContext.new(user: user, query_params: augmented_params)
  end

  def recapitulatif
    authorize(user, :show?)
    @rdv_wizard = AgentPrescripteurRdvWizard.new(agent: current_agent, user: user, query_params: wizard_params, current_domain: current_domain)
    authorize(@rdv_wizard.rdv.motif, :bookable?)

    unless @rdv_wizard.creneau
      flash[:error] = "Ce créneau n'est plus disponible. Veuillez en sélectionner un autre."
      redirect_to(search_creneau_admin_organisation_prescription_path(params[:organisation_id], @rdv_wizard.params_to_selections))
    end
  end

  def create_rdv
    authorize(user, :show?)
    @rdv_wizard = AgentPrescripteurRdvWizard.new(agent: current_agent, user: user, query_params: wizard_params, current_domain: current_domain)
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

  def augmented_params
    params = search_context_params.merge(prescripteur: true)
    geolocation_results = get_geolocation_results(user.address, params[:departement])

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
    params.permit(%i[starts_at rdv_collectif_id] + AgentPrescriptionSearchContext::STRONG_PARAMS_LIST)
  end

  def user
    @user ||= policy_scope(User, policy_scope_class: Agent::UserPolicy::Scope).find(params[:user_ids].first)
  end
end
