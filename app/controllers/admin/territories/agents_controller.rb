# frozen_string_literal: true

class Admin::Territories::AgentsController < Admin::Territories::BaseController
  def index
    @agents = find_agents(params[:q]).page(params[:page])
  end

  def show
    @agent = Agent.find(params[:id])
    authorize @agent
  end

  def search
    @agents = find_agents(params[:q]).limit(10)
    authorize @agent
  end

  def find_agents(search_term)
    organisation_agents = policy_scope_admin(Agent)
      .merge(current_territory.organisations_agents)
      .active
      .complete

    agents = Agent.where(id: organisation_agents) # Use a subquery (IN) instead of .distinct, to be able to sort by an expression
    if search_term.present?
      agents.search_by_text(search_term)
    else
      agents.order_by_last_name
    end
  end

  def edit
    @agent = Agent.find(params[:id])
    authorize @agent
  end

  def update
    @agent = Agent.find(params[:id])
    authorize @agent
    if @agent.update(agent_params)
      redirect_to admin_territory_agents_path(current_territory)
    else
      render :edit
    end
  end

  def agent_params
    params.require(:agent).permit(team_ids: [])
  end
end
