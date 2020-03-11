class Agents::Organisations::RdvsController < AgentAuthController
  def index
    @rdvs = policy_scope(Rdv).where(created_at: Stat::DEFAULT_RANGE)
    @rdvs = @rdvs.status(params[:status]) if params[:status].present?
    @rdvs = @rdvs.includes(:organisation, :motif, agents: :service).order(starts_at: :desc).page(params[:page])
  end
end
