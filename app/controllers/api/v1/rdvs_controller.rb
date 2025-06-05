class Api::V1::RdvsController < Api::V1::AgentAuthBaseController
  def index
    rdvs = policy_scope(Rdv, policy_scope_class: Agent::RdvPolicy::Scope).where(params.permit(:organisation_id))

    rdvs = rdvs.starts_after(Time.zone.parse(params[:starts_after])) if params[:starts_after].present?
    rdvs = rdvs.starts_before(Time.zone.parse(params[:starts_before])) if params[:starts_before].present?

    rdvs = rdvs.includes(:organisation, :motif, :lieu, :agents, :users, participations: [:user], motif: [:motif_category])

    if params[:id].present?
      rdvs = rdvs.where(id: params[:id])
    end

    if params[:user_id].present?
      rdvs = rdvs.where(participations: { user_id: params[:user_id] })
    end

    if params[:agent_id].present?
      rdvs = rdvs.where(agents: { id: params[:agent_id] })
    end

    render_collection(rdvs)
  end
end
