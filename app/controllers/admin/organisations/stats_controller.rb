class Admin::Organisations::StatsController < AgentAuthController
  before_action :set_organisation

  def index
    @stats = Stat.new(
      rdvs: rdv_scope,
      agents: policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope)
        .joins(:organisations).where(organisations: { id: current_organisation.id }),
      users: policy_scope(User)
    )
  end

  def rdvs
    skip_authorization
    stats = Stat.new(rdvs: rdv_scope)
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
    skip_authorization
    render json: Stat.new(users: policy_scope(User)).users_group_by_week
  end

  private

  def rdv_scope
    policy_scope(Rdv).where(organisation: current_organisation)
  end
end
