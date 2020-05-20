class Agents::Organisations::StatsController < AgentAuthController
  respond_to :html, :json

  before_action :set_organisation

  def index
    @stats = Stat.new(rdvs: policy_scope(Rdv), users: policy_scope(User))
  end

  def rdvs
    authorize(@organisation)
    stats = Stat.new(rdvs: policy_scope(Rdv))
    stats = if params[:by_service].present?
              stats.rdvs_group_by_service
            elsif params[:by_location_type].present?
              stats.rdvs_group_by_type
            else
              stats.rdvs_group_by_week_fr
            end
    render json: stats.chart_json
  end

  def users
    authorize(@organisation)
    render json: Stat.new(users: policy_scope(User)).users_group_by_week
  end
end
