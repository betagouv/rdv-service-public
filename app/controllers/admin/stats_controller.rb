class Admin::StatsController < AgentAuthController
  respond_to :html, :json

  def index
    @stats = Stat.new(rdvs: rdvs_for_current_agent)
  end

  def rdvs
    authorize(current_agent, policy_class: Agent::AgentPolicy)
    render json: Stat.new(rdvs: rdvs_for_current_agent).rdvs_group_by_week_fr.chart_json
  end

  private

  def rdvs_for_current_agent
    policy_scope(Rdv).merge(current_agent.rdvs)
  end
end
