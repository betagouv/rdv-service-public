class StatsController < ApplicationController
  layout 'landing'

  def index
    @stats = Stat.new(rdvs: Rdv.all, users: User.all)
  end

  def rdvs
    stats = Stat.new(rdvs: Rdv.all)
    stats = if params[:by_departement].present?
              stats.rdvs_group_by_departement
            else
              stats.rdvs_group_by_week_fr
            end
    render json: stats.chart_json
  end

  def users
    render json: Stat.new(users: User.all).users_group_by_week
  end
end
