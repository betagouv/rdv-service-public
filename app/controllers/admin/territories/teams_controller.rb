# frozen_string_literal: true

class Admin::Territories::TeamsController < Admin::Territories::BaseController
  before_action :set_team, only: %i[show edit update destroy]

  def index
    @teams = policy_scope(Team).page(params[:page])
    @teams = params[:search].present? ? @teams.search_by_text(params[:search]) : @teams.order(:name)
  end

  def new
    @team = Team.new(territory: current_territory)
    authorize @team
  end

  def show
    authorize @team
  end

  def create
    authorize Team
    if (@team = Team.create(team_params.merge(territory: current_territory)))
      redirect_to admin_territory_teams_path(current_territory)
    else
      render :new
    end
  end

  def edit
    authorize @team
  end

  def update
    authorize @team
    if @team.update(team_params)
      redirect_to admin_territory_teams_path(current_territory)
    else
      render :new
    end
  end

  def destroy
    authorize @team
    @team.destroy!
    redirect_to admin_territory_teams_path(current_territory)
  end

  def search
    teams = policy_scope(Team).limit(10)
    @teams = search_params[:term].present? ? teams.search_by_text(search_params[:term]) : teams.order(:name)
  end

  private

  def search_params
    @search_params ||= params.permit(:term)
  end

  def team_params
    params.require(:team).permit(:name, agent_ids: [])
  end

  def set_team
    @team = Team.find(params[:id])
  end
end
