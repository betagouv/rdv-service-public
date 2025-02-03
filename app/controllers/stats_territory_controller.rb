class StatsTerritoryController < ApplicationController
  before_action :set_territory_and_records, except: :index

  def index
    @territories = Territory.all
  end

  def show
    @stats = Stat.new(agents: @agents, organisations: @organisations, rdvs: @rdvs, users: @users, receipts: @receipts)
  end

  def rdvs
    cache_key = ["stats_rdvs", request.query_parameters, Time.zone.today]
    chart_json = Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      stats = Stat.new(rdvs: @rdvs)
      results = if params[:by_territory].present?
                  stats.rdvs_group_by_territory_name
                elsif params[:by_service].present?
                  stats.rdvs_group_by_service
                elsif params[:by_location_type].present?
                  stats.rdvs_group_by_type
                elsif params[:by_status].present?
                  stats.rdvs_group_by_status
                elsif params[:by_participations_status].present?
                  stats.rdvs_group_by_participations_status
                else
                  stats.rdvs_group_by_week_fr
                end
      results.chart_json
    end
    render json: chart_json
  end

  def notifications
    @territories = Territory.all
    @stats = Stat.new(agents: @agents, organisations: @organisations, rdvs: @rdvs, users: @users, receipts: @receipts)
  end

  def receipts
    cache_key = ["stats_receipts", request.query_parameters, Time.zone.today]
    chart_json = Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      attribute = params[:group_by]&.to_sym
      attribute = :channel unless attribute.in?(%i[event channel result])
      Stat.new(receipts: @receipts).receipts_group_by(attribute).chart_json
    end
    render json: chart_json
  end

  def active_agents
    cache_key = ["stats_active_agents", request.query_parameters, Time.zone.today]
    chart_json = Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      Stat.new(rdvs: @rdvs).active_agents_group_by_month.chart_json
    end
    render json: chart_json
  end

  private

  def set_territory_and_records
    @territory = Territory.find(params[:id])
    @rdvs = @territory.rdvs
    @users = @territory.users
    @agents = @territory.organisations_agents
    @organisations = @territory.organisations
    @receipts = @territory.receipts
  end
end
