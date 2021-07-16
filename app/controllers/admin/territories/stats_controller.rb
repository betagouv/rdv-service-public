# frozen_string_literal: true

class Admin::Territories::StatsController < Admin::Territories::BaseController
  def index
    @stats = Stat.new(
      rdvs: Rdv.joins(:organisation).where(organisations: { id: current_territory.organisations.map(&:id) }),
      agents: Agent.joins(:organisations).where(organisations: { id: current_territory.organisations.map(&:id) }),
      users: User.joins(:organisations).where(organisations: { id: current_territory.organisations.map(&:id) })
    )
  end

  def rdvs
    skip_authorization
    stats = Stat.new(rdvs: Rdv.joins(:organisation).where(organisations: { id: current_territory.organisations.map(&:id) }))
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
    render json: Stat.new(users: User.joins(:organisations).where(organisations: { id: current_territory.organisations.map(&:id) })).users_group_by_week
  end
end
