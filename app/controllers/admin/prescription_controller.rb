class Admin::PrescriptionController < AgentAuthController
  def search_creneau
    authorize(user, :show?)
    @context = AgentPrescriptionSearchContext.new(user: user, query_params: search_context_params.merge(prescripteur: true))
  end

  def recapitulatif
    authorize(user, :show?)
    @rdv_wizard = AgentPrescripteurRdvWizard.new(agent_prescripteur: current_agent, user: user, query_params: wizard_params)
    authorize(@rdv_wizard.rdv.motif, :bookable?)

    unless @rdv_wizard.creneau
      flash[:error] = "Ce créneau n'est plus disponible. Veuillez en sélectionner un autre."
      redirect_to(search_creneau_admin_organisation_prescription_path(params[:organisation_id], @rdv_wizard.params_to_selections))
    end
  end

  def create_rdv
    authorize(user, :show?)
    @rdv_wizard = AgentPrescripteurRdvWizard.new(agent_prescripteur: current_agent, user: user, query_params: wizard_params)
    authorize(@rdv_wizard.rdv.motif, :bookable?)

    @rdv_wizard.create!
    redirect_to confirmation_admin_organisation_prescription_path(rdv_id: @rdv_wizard.rdv.id)
  end

  def confirmation
    @rdv = Rdv.find(params[:rdv_id])
    authorize(@rdv)
  end

  private

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
