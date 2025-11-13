class StatsController < ApplicationController
  before_action :set_territory_and_records, only: %i[territory territory_rdvs]

  def index; end

  def lieux_map_data
    query = Rails.root.join("app/lib/lieux_map_query.sql").read
    res_body = Rails.cache.fetch("lieux_map_data", expires_in: 24.hours) { MetabaseApi.sql_query(query, raw_json: true) }
    json = JSON.parse(res_body)
    render(json:)
  rescue MetabaseApi::Error => e
    render(json: { error: e.message }, status: :internal_server_error)
  end

  def territories
    @territories = Territory.all
  end

  def territory
    @stats = Stat.new(agents: @agents, organisations: @organisations, rdvs: @rdvs, users: @users, receipts: @receipts)
  end

  def territory_rdvs
    cache_key = ["stats_rdvs", request.query_parameters, Time.zone.today]
    chart_json = Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      stats = Stat.new(rdvs: @rdvs)
      results = if params[:by_service].present?
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

  private

  def set_territory_and_records
    @territory = Territory.find(params[:territory])
    @rdvs = @territory.rdvs
    @users = @territory.users
    @organisations = @territory.organisations
  end
end
