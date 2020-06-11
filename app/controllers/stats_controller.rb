class StatsController < ApplicationController
  before_action :scope_rdv_to_departement

  def index
    @stats = Stat.new(agents: @agents, organisations: @organisations, rdvs: @rdvs, users: @users)
  end

  def rdvs
    stats = Stat.new(rdvs: @rdvs)
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

  def agents
    render json: Stat.new(agents: @agents).agents_group_by_week
  end

  def organisations
    render json: Stat.new(organisations: @organisations).organisations_group_by_week
  end

  def users
    render json: Stat.new(users: @users).users_group_by_week
  end

  def scope_rdv_to_departement
    @departement = params[:departement]
    if @departement.present?
      @rdvs = Rdv.joins(:organisation).where(organisations: { departement: @departement })
      @users = User.joins(:organisations).where(organisations: { departement: @departement })
      @agents = Agent.joins(:organisations).where(organisations: { departement: @departement })
      @organisations = Organisation.where(organisations: { departement: @departement })
    else
      @rdvs = Rdv.all
      @users = User.all
      @agents = Agent.all
      @organisations = Organisation.all
    end

    @departements = Organisation.all.map(&:departement).uniq.sort
  end
end
