class Admin::Organisations::RdvsController < AgentAuthController
  def index
    @rdvs = policy_scope(Rdv)
    @rdvs = @rdvs.default_stats_period if params[:default_period].present?
    @rdvs = @rdvs.status(params[:status]) if params[:status].present?
    @rdvs = @rdvs.includes(:organisation, :motif, agents: :service).order(starts_at: :desc)
    @rdvs = @rdvs.with_agent(Agent.find(params[:agent_id])) if params[:agent_id].present?

    respond_to do |format|
      format.xls { send_data(RdvExporterService.perform_with(@rdvs, StringIO.new), filename: "rdvs.xls", type: "application/xls") }
      format.html { @rdvs = @rdvs.page(params[:page]) }
    end
  end
end
