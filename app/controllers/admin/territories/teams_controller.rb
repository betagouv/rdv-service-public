class Admin::Territories::TeamsController < Admin::Territories::BaseController
  before_action :set_team, only: %i[show edit update destroy]

  respond_to :html, :json

  def index
    @teams = policy_scope(current_territory.teams, policy_scope_class: Agent::TeamPolicy::Scope).page(page_number)
    @teams = params[:term].present? ? @teams.search_by_text(params[:term]) : @teams.ordered_by_name
  end

  def new
    @team = Team.new(territory: current_territory)
    authorize @team
  end

  def show
    authorize @team
  end

  def create
    @team = Team.new(team_params.merge(territory: current_territory))
    authorize @team

    if @team.save
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

  # On est obligé de redéfinir cette méthode ici tant que le controller parent utilise les AgentTerritorialContext
  def pundit_user
    current_agent
  end

  private

  def team_params
    params.require(:team).permit(:name, agent_ids: [])
  end

  def set_team
    @team = Team.find(params[:id])
  end
end
