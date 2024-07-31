class Agents::TeamsController < AgentAuthController
  respond_to :json

  def index
    territory = Territory.find(params.require(:territory_id))
    @teams = policy_scope(territory.teams, policy_scope_class: Agent::TeamPolicy::Scope).page(page_number)
    @teams = params[:term].present? ? @teams.search_by_text(params[:term]) : @teams.ordered_by_name
  end

  private

  def pundit_user
    current_agent
  end
end
