class StatsController < ApplicationController
  def index
    @stats = Stat.new(rdvs: Rdv.all, users: User.all)
  end

  def rdvs
    stats = Stat.new(rdvs: Rdv.all)
    stats = if params[:by_departement].present?
              stats.rdvs_group_by_departement
            elsif params[:by_service].present?
              stats.rdvs_group_by_service
            elsif params[:by_location_type].present?
              stats.rdvs_group_by_type
            else
              stats.rdvs_group_by_week_fr
            end
    render json: stats.chart_json
  end

  def users
    render json: Stat.new(users: User.all).users_group_by_week
  end
end
