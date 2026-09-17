class Agents::ProConnectLinkingController < AgentAuthController
  layout "application_agent_config"

  def show
    authorize(current_agent, policy_class: Agent::AgentPolicy)
  end

  def create
    authorize(current_agent, policy_class: Agent::AgentPolicy)

    email = current_agent.email
    sign_out(current_agent)
    redirect_to pro_connect_auth_path(login_hint: email, user_type: "agent")
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end
