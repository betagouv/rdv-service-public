class Agents::ProConnectLinkingController < AgentAuthController
  layout "application_agent_config"

  def show
    @agent = current_agent
    authorize(@agent, policy_class: Agent::AgentPolicy)
  end

  def create
    @agent = current_agent
    authorize(@agent, policy_class: Agent::AgentPolicy)

    email = @agent.email
    sign_out(@agent)
    redirect_to pro_connect_auth_path(login_hint: email, user_type: "agent")
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end
