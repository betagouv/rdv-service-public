class Admin::Territories::AgentsController < Admin::Territories::BaseController
  before_action :set_agent, only: %i[edit update_teams territory_admin update_services]
  before_action :authorize_agent, only: %i[edit update_teams territory_admin update_services]

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
    authorize_with_legacy_configuration_scope(@agent)
  end

  def edit; end

  def update_teams
    # ATTENTION: ce update peut supprimer des team_ids d’autres territoires.
    # C’est un bug consciemment laissé pour l’instant puisqu'on a pas ou peu d'agents multi-territoire et que les équipes ne sont pas utilisées par la plupart des territoires
    # cf PR https://github.com/betagouv/rdv-service-public/pull/4525 qui tentait de résoudre ça.
    team_ids = params[:agent][:team_ids].compact_blank
    if @agent.update(team_ids:)
      flash[:success] = "Les équipes de l’agent ont été mises à jour"
      redirect_to edit_admin_territory_agent_path(current_territory, @agent.id)
    else
      render :edit
    end
  end

  def create
    authorize_with_legacy_configuration_scope(Agent.new(permitted_create_params))

    organisation_ids = params.require(:admin_agent).require(:organisation_ids)
    context = AgentTerritorialContext.new(@current_agent, nil) # Dès que possible, on arrêtera d'utiliser ces contextes
    authorized_organisations = Agent::OrganisationPolicy::Scope.new(context, Organisation.where(id: organisation_ids)).resolve

    create_agent = AdminCreatesAgent.new(
      agent_params: permitted_create_params,
      current_agent: current_agent,
      organisations: authorized_organisations,
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

  def territory_admin
    if params[:territorial_admin] == "1"
      @agent.territorial_admin!(current_territory)
      message = "Les droits d'administrateur du #{current_territory} ont été ajouté(e) a #{@agent.full_name}"
    else
      @agent.remove_territorial_admin!(current_territory)
      message = "Les droits d'administrateur du #{current_territory} ont été retiré(e) a #{@agent.full_name}"
    end
    redirect_to(
      edit_admin_territory_agent_path(current_territory, @agent),
      flash: { success: message }
    )
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

  def pundit_user
    AgentTerritorialContext.new(current_agent, current_territory)
  end

  def authorize_with_legacy_configuration_scope(record, *args, **kwargs)
    # L'utilisation de configuration est un legacy qui a l'inconvénient de distinguer les permissions en fonction de la page sur laquelle on est en train de naviguer
    # On préfère que le controller applique le filtre pertinent, et que les policy indiquent les permissions dans l'absolu, indépendamment de la page courante.
    authorize([:configuration, record], *args, **kwargs)
  end

  def set_agent
    @agent = Agent.active.find(params[:id])
  end

  def authorize_agent
    authorize_with_legacy_configuration_scope @agent
  end

  def permitted_create_params
    params.require(:admin_agent).permit(:email, service_ids: [])
  end
end
