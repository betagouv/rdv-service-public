# frozen_string_literal: true

class Admin::Territories::AgentsController < Admin::Territories::BaseController
  def index
    @agents = find_agents(params[:q]).page(params[:page])
  end

  def find_agents(search_term)
    organisation_agents = policy_scope(Agent)
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
end
