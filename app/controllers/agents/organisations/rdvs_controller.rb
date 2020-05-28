class Agents::Organisations::RdvsController < AgentAuthController
  def index
    @rdvs = policy_scope(Rdv)
    @rdvs = @rdvs.default_stats_period if params[:default_period].present?
    @rdvs = @rdvs.status(params[:status]) if params[:status].present?
    @rdvs = @rdvs.includes(:organisation, :motif, agents: :service).order(starts_at: :desc)

    respond_to do |format|
      format.ods { send_data(RdvExporterService.perform_with(@rdvs, StringIO.new), filename: "stats.ods", type: "application/ods") }
      format.html { @rdvs = @rdvs.page(params[:page]) }
    end
  end
end
