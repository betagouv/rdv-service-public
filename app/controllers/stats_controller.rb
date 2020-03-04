class StatsController < ApplicationController
  layout 'landing'

  def index
    @stats = Stat.new(rdvs: Rdv.all, users: User.all)
  end

  def rdvs
    render json: Stat.new(rdvs: Rdv.all).rdv_group_by_week_fr.chart_json
  end

  def users
    render json: Stat.new(users: User.all).users_group_by_week
  end
end
