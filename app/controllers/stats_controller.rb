class StatsController < ApplicationController
  layout 'landing'

  def index
    @rdvs = Rdv.all
    @users = User.active
  end

  def rdvs
    render json: Rdv.group(:created_by).group_by_month('rdvs.created_at', range: Time.zone.now.beginning_of_year..Time.zone.now, format: '%b %y').count.transform_keys { |key| key[0] == 'agent' ? ['agent', key[1]] : ['usager', key[1]] }.chart_json
  end

  def users
    render json: User.active.group_by_month('users.created_at', range: Time.zone.now.beginning_of_year..Time.zone.now, format: '%b %y').count
  end
end
