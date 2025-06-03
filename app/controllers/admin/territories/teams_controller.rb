class Admin::Territories::TeamsController < Admin::Territories::BaseController
  before_action :set_team, only: %i[edit update destroy]

  def index
    @teams = policy_scope(current_territory.teams, policy_scope_class: Agent::TeamPolicy::Scope).page(page_number)
    @teams = params[:term].present? ? @teams.search_by_text(params[:term]) : @teams.ordered_by_name
  end

  def new
    @team = Team.new(territory: current_territory)
    authorize(@team, policy_class: Agent::TeamPolicy)
  end

  def create
    @team = Team.new(team_params.merge(territory: current_territory))
    authorize(@team, policy_class: Agent::TeamPolicy)

    if @team.save
      redirect_to admin_territory_teams_path(current_territory)
    else
      render :new
    end
  end

  def edit
    authorize(@team, policy_class: Agent::TeamPolicy)
  end

  def update
    # On utilise ici une transaction pour pouvoir rollback si le second
    # authorize détecte des `agent_ids` non autorisés et lève une exception.
    Team.transaction do
      authorize(@team, policy_class: Agent::TeamPolicy)
      @team.assign_attributes(team_params)
      authorize(@team, policy_class: Agent::TeamPolicy)
    end
    if @team.save
      redirect_to admin_territory_teams_path(current_territory)
    else
      render :new
    end
  end

  def destroy
    authorize(@team, policy_class: Agent::TeamPolicy)
    @team.destroy!
    redirect_to admin_territory_teams_path(current_territory)
  end

  private

  def team_params
    params.require(:team).permit(:name, agent_ids: [])
  end

  def set_team
    @team = Team.find(params[:id])
  end
end
