class Agents::Organisations::StatsController < AgentAuthController
  respond_to :html, :json

  before_action :set_organisation

  def index
    @stats = Stat.new(rdvs: policy_scope(Rdv), users: policy_scope(User))
  end

  def rdvs
    authorize(@organisation)
    render json: Stat.new(rdvs: policy_scope(Rdv)).rdvs_group_by_week_fr.chart_json
  end

  def users
    authorize(@organisation)
    render json: Stat.new(users: policy_scope(User)).users_group_by_week
  end
end
