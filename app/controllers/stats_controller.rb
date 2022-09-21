# frozen_string_literal: true

class StatsController < ApplicationController
  before_action :scope_rdv_to_territory

  def index
    @territories = Territory.all
    @stats = Stat.new(agents: @agents, organisations: @organisations, rdvs: @rdvs, users: @users, receipts: @receipts)
  end

  def rdvs
    stats = Stat.new(rdvs: @rdvs)
    stats = if params[:by_territory].present?
              stats.rdvs_group_by_territory_name
            elsif params[:by_service].present?
              stats.rdvs_group_by_service
            elsif params[:by_location_type].present?
              stats.rdvs_group_by_type
            elsif params[:by_status].present?
              stats.rdvs_group_by_status
            else
              stats.rdvs_group_by_week_fr
            end
    render json: stats.chart_json
  end

  def receipts
    attribute = params[:group_by]&.to_sym
    attribute = :channel unless attribute.in?(%i[event channel result])
    render json: Stat.new(receipts: @receipts).receipts_group_by(attribute).chart_json
  end

  def active_agents
    stats = Stat.new(rdvs: @rdvs).active_agents_group_by_month
    render json: stats.chart_json
  end

  def scope_rdv_to_territory
    if params[:territory].present?
      @territory = Territory.find(params[:territory])
      @rdvs = @territory.rdvs
      @users = @territory.users
      @agents = @territory.organisations_agents
      @organisations = @territory.organisations
      @receipts = @territory.receipts
    else
      @rdvs = Rdv.all
      @users = User.all
      @agents = Agent.all
      @organisations = Organisation.all
      @receipts = Receipt.all
    end
  end
end
