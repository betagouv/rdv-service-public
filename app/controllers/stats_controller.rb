class StatsController < ApplicationController
  layout 'landing'

  def index
    @rdvs = Rdv.all
    @users = User.active
  end

  def rdvs
    render json: Rdv.group(:created_by).group_by_week('rdvs.created_at', range: 16.weeks.ago..Time.zone.now).count.transform_keys { |key| key[0] == 'agent' ? ['agent', key[1]] : ['usager', key[1]] }.chart_json
  end

  def users
    render json: User.active.group_by_week('users.created_at', range: 16.weeks.ago..Time.zone.now).count
  end
end
