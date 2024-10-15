class Api::V1::RdvsController < Api::V1::AgentAuthBaseController
  def index
    rdvs = policy_scope(Rdv, policy_scope_class: Agent::RdvPolicy::Scope).where(params.permit(:organisation_id))
    rdvs = rdvs.starts_after(Time.zone.parse(params[:starts_after])) if params[:starts_after].present?
    rdvs = rdvs.starts_before(Time.zone.parse(params[:starts_before])) if params[:starts_before].present?
    render_collection(rdvs)
  end
end
