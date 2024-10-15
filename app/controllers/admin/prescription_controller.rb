class Admin::PrescriptionController < AgentAuthController
  before_action :set_rdv_wizard, only: %i[user_selection recapitulatif create_rdv]
  before_action :redirect_if_creneau_unavailable, only: %i[user_selection recapitulatif create_rdv]

  def search_creneau
    skip_authorization
    session[:agent_prescripteur_organisation_id] = params[:organisation_id]
    @context = AgentPrescriptionSearchContext.new(
      user: user,
      query_params: search_context_params.merge(prescripteur: Prescripteur::INTERNE),
      current_organisation: current_organisation,
      agent_prescripteur: current_agent
    )
  end

  def user_selection
    skip_authorization
  end

  def recapitulatif
    authorize(user, :prescribe?, policy_class: Agent::UserPolicy)
    authorize(@rdv_wizard.rdv.motif, :bookable?, policy_class: Agent::MotifPolicy)
  end

  def create_rdv
    # TODO: Autoriser sur la participation (vérifier que le current_agent accéde au user et au motif)
    authorize(user, :prescribe?, policy_class: Agent::UserPolicy)
    authorize(@rdv_wizard.rdv.motif, :bookable?, policy_class: Agent::MotifPolicy)

    @rdv_wizard.create!
    redirect_to confirmation_admin_organisation_prescription_path(participation_id: @rdv_wizard.participation.id)
  end

  def confirmation
    participation = Participation.find(params[:participation_id])
    @rdv = participation.rdv
    authorize(participation, :show?, policy_class: Agent::ParticipationPolicy)
  end

  private

  def set_rdv_wizard
    @rdv_wizard = AgentPrescripteurRdvWizard.new(query_params: wizard_params, agent_prescripteur: current_agent, domain: current_domain, current_organisation: current_organisation)
  end

  def redirect_if_creneau_unavailable
    unless @rdv_wizard.creneau
      flash[:error] = "Ce créneau n'est plus disponible. Veuillez en sélectionner un autre."
      redirect_to(search_creneau_admin_organisation_prescription_path(params[:organisation_id], @rdv_wizard.params_to_selections))
    end
  end

  def search_context_params
    params.permit(AgentPrescriptionSearchContext::STRONG_PARAMS_LIST)
  end

  def wizard_params
    # Ces paramètres permettent de passer du choix de creneau au wizard (create et récapitulatif)
    params.permit(%i[starts_at rdv_collectif_id] + AgentPrescriptionSearchContext::STRONG_PARAMS_LIST)
  end

  def user
    user_ids = Array(params[:user_ids]).compact_blank
    return if user_ids.empty?

    scope = Agent::UserPolicy::TerritoryScope.new(pundit_user, User.all).resolve
    @user ||= scope.find_by_id(user_ids.first)
  end
end
