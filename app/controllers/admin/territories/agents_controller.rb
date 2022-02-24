# frozen_string_literal: true

class Admin::Territories::AgentsController < Admin::Territories::BaseController
  before_action :set_agent, only: %i[edit update]
  before_action :authorize_agent, only: %i[edit update]

  def index
    @agents = find_agents(params[:q]).page(params[:page])
  end

  def search
    @agents = find_agents(params[:q]).limit(10)
  end

  def find_agents(search_term)
    organisation_agents = policy_scope(Agent)
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

  def edit; end

  def update
    if @agent.update(agent_params)
      redirect_to admin_territory_agents_path(current_territory)
    else
      render :edit
    end
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
