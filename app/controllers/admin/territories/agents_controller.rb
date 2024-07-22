class Admin::Territories::AgentsController < Admin::Territories::BaseController
  before_action :set_agent, only: %i[edit update territory_admin update_services]
  before_action :authorize_agent, only: %i[edit update territory_admin update_services]

  def index
    @agents = find_agents(params[:q]).page(page_number)
  end

  def find_agents(search_term)
    organisation_agents = policy_scope(Agent)
      .active
      .complete

    agents = Agent.where(id: organisation_agents) # Use a subquery (IN) instead of .distinct, to be able to sort by an expression
    if search_term.present?
      agents.search_by_text(search_term)
    else
      agents.ordered_by_last_name
    end
  end

  def edit; end

  def update
    if @agent.update(agent_update_params)
      flash[:success] = "L'agent a été mis à jour"
      redirect_to edit_admin_territory_agent_path(current_territory, @agent.id)
    else
      render :edit
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

  def set_agent
    @agent = Agent.active.find(params[:id])
  end

  def authorize_agent
    authorize @agent
  end

  def agent_update_params
    params.require(:agent).permit(team_ids: [])
  end
end
