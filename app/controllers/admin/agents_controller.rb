class Admin::AgentsController < AgentAuthController
  respond_to :html

  before_action :ensure_agent_is_admin, except: :index
  helper_method :agents_search_params

  def index
    @agents_search_form = Admin::AgentsSearchForm.new(current_organisation:, query: params.dig(:search, :query), role: params.dig(:search, :role))
    agents_scope = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope).active
    @agents = @agents_search_form.filter_agents(agents_scope)
    @agents = @agents.includes(:services, :roles, :organisations)
    @agents = @agents.page(page_number)
    @display_services = current_territory.services.any? || current_organisation.agents.joins(:agent_services).any?
    @agents_filtered_out_count = @agents_search_form.organisation_scope(agents_scope).count - @agents.total_count
  end

  def new
    @agent = Agent.new(organisations: [current_organisation])
    authorize(@agent, policy_class: Agent::AgentPolicy)

    render_new
  end

  def create
    authorize(Agent.new(organisations: [current_organisation]), policy_class: Agent::AgentPolicy)

    create_agent = AdminCreatesAgent.new(
      agent_params: create_agent_params,
      current_agent: current_agent,
      organisations: [current_organisation],
      access_level: params[:agent][:agent_role][:access_level],
      agent_accueil: params[:agent][:agent_role][:agent_accueil]
    )

    @agent = create_agent.call

    if @agent.valid?
      flash[:success] = create_agent.confirmation_message
      flash[:alert] = create_agent.warning_message
      redirect_to admin_organisation_agents_path(current_organisation)
    else
      @pending_invitation_conflict_organisation = create_agent.pending_invitation_conflict_organisation
      render_new
    end
  end

  def edit
    @agent = Agent.find(params[:id])
    authorize(@agent, policy_class: Agent::AgentPolicy)

    render_edit
  end

  def update
    @agent = Agent.find(params[:id])
    authorize(@agent, policy_class: Agent::AgentPolicy)

    update_agent = AdminUpdatesAgent.new(
      agent: @agent,
      organisation: current_organisation,
      new_access_level: params[:agent][:agent_role][:access_level],
      new_agent_accueil: params[:agent][:agent_role][:agent_accueil],
      agent_params: update_agent_params,
      inviting_agent: current_agent
    )

    if update_agent.call
      flash[:success] = update_agent.confirmation_message

      redirect_to admin_organisation_agents_path(current_organisation)
    else
      render_edit
    end
  end

  def destroy
    @agent = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope).find(params[:id])
    authorize(@agent, policy_class: Agent::AgentPolicy)

    agent_removal = AgentRemoval.new(@agent, current_organisation)

    if agent_removal.valid?
      agent_removal.remove!
      flash[:notice] = agent_removal.confirmation_message

      redirect_to admin_organisation_agents_path(current_organisation)
    else
      redirect_to edit_admin_organisation_agent_path(current_organisation, @agent), flash: { error: agent_removal.errors.full_messages.join }
    end
  end

  private

  def ensure_agent_is_admin
    raise Pundit::NotAuthorizedError unless current_agent.admin_in_organisation?(current_organisation)
  end

  def render_new
    @services = current_territory.services.reject(&:secretariat?)
    @roles = access_levels_collection
    @agent_role = AgentRole.new

    render :new, layout: "application_agent"
  end

  def render_edit
    @services = @agent.services # les services sont en lecture seule en édition
    @agent_role = @agent.roles.find { |r| r.organisation == current_organisation }
    @agent_removal_presenter = AgentRemovalPresenter.new(@agent, current_organisation)
    @roles = access_levels_collection

    render :edit
  end

  def access_levels_collection
    if @agent != current_agent && @agent.organisations.count < 2
      AgentRole::ACCESS_LEVELS_WITH_INTERVENANT
    else
      AgentRole::ACCESS_LEVELS
    end
  end

  def create_agent_params
    params.require(:agent).permit(:email, :last_name, service_ids: [])
  end

  def update_agent_params
    params.require(:agent).permit(:email, :last_name, :first_name)
  end
end
