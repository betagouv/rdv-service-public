class Api::Rdvinsertion::AgentAuthBaseController < Api::V1::AgentAuthBaseController
  private

  def authenticate_agent
    authenticate_agent_with_shared_secret
  end
end
