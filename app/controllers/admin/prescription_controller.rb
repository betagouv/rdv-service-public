class Admin::PrescriptionController < AgentAuthController
  def search_creneau
    skip_authorization
    @context = AgentPrescriptionSearchContext.new(user: user, query_params: search_context_params.merge(prescripteur: true))
  end

  def recapitulatif
    skip_authorization
    @rdv_wizard = AgentPrescripteurRdvWizard.new(query_params: wizard_params)

    unless @rdv_wizard.creneau
      flash[:error] = "Ce créneau n'est plus disponible. Veuillez en sélectionner un autre."
      redirect_to(search_creneau_admin_organisation_prescription_path(params[:organisation_id], @rdv_wizard.params_to_selections))
    end
  end

  def create_rdv
    skip_authorization

    @rdv_wizard = AgentPrescripteurRdvWizard.new(query_params: wizard_params)

    rdv = @rdv_wizard.create_rdv!
    redirect_to confirmation_admin_organisation_prescription_path(rdv_id: rdv.id)
  end

  def confirmation
    skip_authorization # TODO: remove this
    @rdv = Rdv.find(params[:rdv_id])
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
