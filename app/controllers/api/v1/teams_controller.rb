class Api::V1::TeamsController < Api::V1::AgentAuthBaseController
  def index
    teams = policy_scope(Team, policy_scope_class: Agent::TeamPolicy::Scope)
    render_collection(teams)
  end

  private

  def pundit_user
    current_agent
  end
end
