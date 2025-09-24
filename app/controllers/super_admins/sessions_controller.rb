module SuperAdmins
  class SessionsController < ApplicationController
    def destroy
      agent_connect_id_token = session.delete(:agent_connect_id_token)
      skip_authorization
      sign_out_all_scopes if super_admin_signed_in?

      if agent_connect_id_token.present?
        agent_connect_client = AgentConnectOpenIdClient::Logout.new(agent_connect_id_token)

        redirect_to agent_connect_client.agent_connect_logout_url(root_url), allow_other_host: true
      else
        redirect_to root_path
      end
    end
  end
end
