# frozen_string_literal: true

class Admin::Territories::AgentsController < Admin::Territories::BaseController
  before_action :set_agent, only: %i[edit update territory_admin]
  before_action :authorize_agent, only: %i[edit update territory_admin]

  def index
    @agents = find_agents(params[:q]).page(params[:page])
  end

  def find_agents(search_term)
    organisation_agents = policy_scope(Agent)
      .complete

    agents = Agent.where(id: organisation_agents) # Use a subquery (IN) instead of .distinct, to be able to sort by an expression
    if search_term.present?
      agents.search_by_text(search_term)
    else
      agents.order_by_last_name
    end
  end

  def edit; end

  def update
    if @agent.update(agent_params)
      redirect_to admin_territory_agents_path(current_territory)
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

  private

  def set_agent
    @agent = Agent.find(params[:id])
  end

  def authorize_agent
    authorize @agent
  end

  def agent_params
    params.require(:agent).permit(team_ids: [])
  end
end
