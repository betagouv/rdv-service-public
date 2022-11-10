# frozen_string_literal: true

class Admin::Organisations::StatsController < AgentAuthController
  before_action :set_organisation

  def index
    @stats = Stat.new(
      rdvs: policy_scope(Rdv).where(organisation: current_organisation),
      agents: policy_scope(Agent)
        .joins(:organisations).where(organisations: { id: current_organisation.id }),
      users: policy_scope(User)
    )
  end

  def rdvs
    skip_authorization
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
    skip_authorization
    render json: Stat.new(users: policy_scope(User)).users_group_by_week
  end
end
