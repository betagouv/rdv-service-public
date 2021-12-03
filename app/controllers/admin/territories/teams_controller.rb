# frozen_string_literal: true

class Admin::Territories::TeamsController < Admin::Territories::BaseController
  def index
    @teams = current_territory.teams
  end

  def new
    @team = Team.new
  end

  def create
    if (@team = Team.create(team_params.merge(territory: current_territory)))
      redirect_to admin_territory_teams_path(current_territory)
    else
      render :new
    end
  end

  def edit
    @team = Team.find(params[:id])
  end

  def update
    @team = Team.find(params[:id])
    if @team.update(team_params)
      redirect_to admin_territory_teams_path(current_territory)
    else
      render :new
    end
  end

  def destroy
    team = Team.find(params[:id])
    team.destroy!
    redirect_to admin_territory_teams_path(current_territory)
  end

  def team_params
    params.require(:team).permit(:name, agent_ids: [])
  end
end
