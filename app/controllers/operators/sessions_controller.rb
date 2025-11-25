class Operators::SessionsController < Devise::SessionsController
  def destroy
    agent_connect_id_token = session.delete(:agent_connect_id_token)

    sign_out(:operator_manager)

    agent_connect_client = AgentConnectOpenIdClient::Logout.new(agent_connect_id_token)

    redirect_to agent_connect_client.agent_connect_logout_url(root_url), allow_other_host: true
  end
end
