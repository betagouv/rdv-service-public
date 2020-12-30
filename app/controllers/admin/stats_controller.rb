class Admin::StatsController < AgentAuthController
  respond_to :html, :json

  def index
    @stats = Stat.new(rdvs: rdvs_for_current_agent)
  end

  def rdvs
    authorize(current_agent)
    respond_to do |format|
      format.xls { send_data(RdvExporter.export(rdvs_for_current_agent, StringIO.new), filename: "rdvs.xls", type: "application/xls") }
      format.json { render json: Stat.new(rdvs: rdvs_for_current_agent).rdvs_group_by_week_fr.chart_json }
    end
  end

  private

  def rdvs_for_current_agent
    policy_scope(Rdv).with_agent(current_agent)
  end
end
