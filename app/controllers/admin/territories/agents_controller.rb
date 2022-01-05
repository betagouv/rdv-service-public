# frozen_string_literal: true

class Admin::Territories::AgentsController < Admin::Territories::BaseController
  def index
    @agents = Agent.joins(:roles).where(agents_organisations: { organisation_id: Territory.first.organisations || [] }).page(params[:page])
    @agents = params[:search].present? ? @agents.search_by_text(params[:search]) : @agents.order_by_last_name
  end

  def search
    agents = policy_scope_admin(Agent)
      .joins(:organisations).where(organisations: { id: current_territory.organisations.map(&:id) })
      .active.complete.limit(10)
    @agents = search_params[:term].present? ? agents.search_by_text(search_params[:term]) : agents.order_by_last_name

    skip_authorization
  end

  def edit
    @agent = Agent.find(params[:id])
  end

  def update
    @agent = Agent.find(params[:id])
    if @agent.update(agent_params)
      redirect_to admin_territory_agents_path(current_territory)
    else
      render :edit
    end
  end

  def agent_params
    params.require(:agent).permit(team_ids: [])
  end

  def search_params
    @search_params ||= begin
      search_params = params.permit(:term)
      search_params[:term] = clean_search_term(search_params[:term])
      search_params
    end
  end

  def clean_search_term(term)
    return nil if term.blank?

    I18n.transliterate(term)
  end
end
