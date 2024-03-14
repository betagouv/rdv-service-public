class Api::Rdvinsertion::AgentAuthBaseController < Api::V1::AgentAuthBaseController
  before_action :authenticate_agent

  private

  def authenticate_agent
    authenticate_agent_with_shared_secret
  end
end
