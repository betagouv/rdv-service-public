class Api::V1::ParticipationsController < Api::V1::AgentAuthBaseController
  def update
    participation = policy_scope(Participation, policy_scope_class: Agent::ParticipationPolicy::Scope).find(params[:id])

    if participation_params[:status].present?
      participation.change_status_and_notify(current_agent, participation_params[:status])
    end

    render_record participation.rdv
  end

  private

  # On fait cela sinon current_organisation est nil
  # Cela empêche can_access_others_planning? de renvoyer une valeur dans le scope de la policy RDV et on limite les rdvs visibles même quand on doit y avoir accés
  # TODO : Revoir le fonctionnement de current_organisation dans les scopes

  def current_organisation
    @current_organisation ||= Participation.find(params[:id]).rdv.organisation
  end

  def participation_params
    params.require(:participation).permit(:status)
  end
end
