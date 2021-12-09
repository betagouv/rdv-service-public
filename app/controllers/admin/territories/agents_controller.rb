# frozen_string_literal: true

class Admin::Territories::AgentsController < Admin::Territories::BaseController
  def index
    @agents = Agent.joins(:roles).where(agents_organisations: { organisation_id: Territory.first.organisations || [] }).page(params[:page])
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
end
