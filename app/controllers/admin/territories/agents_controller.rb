class TeamsInMultipleTerritoriesError < StandardError; end

class Admin::Territories::AgentsController < Admin::Territories::BaseController
  before_action :set_agent, only: %i[edit update_teams update_services]

  def index
    @agents = find_agents(params[:q]).page(page_number)
  end

  def find_agents(search_term)
    territory_agents = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope)
      .active
      .complete
      .joins(:agent_territorial_access_rights).where(agent_territorial_access_rights: { territory_id: current_territory.id })

    agents = Agent.where(id: territory_agents) # Use a subquery (IN) instead of .distinct, to be able to sort by an expression
    if search_term.present?
      agents.search_by_text(search_term)
    else
      agents.ordered_by_last_name
    end
  end

  def new
    @agent = Agent.new
    skip_authorization
    # l’agent n’étant pas lié à un territoire la policy ne fonctionne pas
    # Admin::Territories::BaseController#set_territory limite néanmoins l’accès à cette page aux admins du territoire
  end

  def edit; end

  def update_teams
    # cf PR https://github.com/betagouv/rdv-service-public/pull/4525
    raise TeamsInMultipleTerritoriesError if @agent.teams.where.not(territory: current_territory).exists?

    team_ids = Team
      .where(id: params[:agent][:team_ids].compact_blank, territory: current_territory) # filtering on territory is not done in policy anymore
      .pluck(:id)
    if @agent.update(team_ids:)
      flash[:success] = "Les équipes de l’agent ont été mises à jour"
      redirect_to edit_admin_territory_agent_path(current_territory, @agent.id)
    else
      render :edit
    end
  end

  def create
    all_params = params.require(:admin_agent).permit(:email, service_ids: [], organisation_ids: [])
    new_agent = Agent.new(all_params)
    authorize [:configuration, new_agent]

    create_agent = AdminCreatesAgent.new(
      agent_params: all_params.slice(:email, :service_ids),
      current_agent: current_agent,
      organisations: Organisation.where(id: all_params[:organisation_ids]),
      access_level: AgentRole::ACCESS_LEVEL_BASIC
    )

    @agent = create_agent.call

    if @agent.valid?
      flash[:notice] = create_agent.confirmation_message
      flash[:alert] = create_agent.warning_message
      redirect_to admin_territory_agents_path(current_territory)
    else
      render :new
    end
  end

  def update_services
    service_ids = params[:agent][:service_ids].compact_blank
    form_validator = AdminChangesAgentServices.new(@agent, service_ids)
    if form_validator.valid? && @agent.update(service_ids: service_ids)
      flash[:success] = "Les services de l'agent on été modifiés"
      redirect_to edit_admin_territory_agent_path(current_territory, @agent.id)
    else
      @agent.errors.copy!(form_validator.errors)
      render :edit
    end
  end

  private

  def set_agent
    @agent = Agent.active.find(params[:id])
    authorize [:configuration, @agent]
  end
end
