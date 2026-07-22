class Api::Rdvinsertion::AgentAuthBaseController < Api::V1::AgentAuthBaseController
  private

  # L'authentification par secret partagé est faite via un secret partagé avec rdv-insertion qui se trouve
  # dans la variable d'environnement `SHARED_SECRET_FOR_AGENTS_AUTH`. Elle a vocation à disparaître.
  # L'authentification par OAuth sera la seule méthode d'authentification valide.
  def authenticate_agent
    if request.headers.include?("X-Agent-Auth-Signature")
      authenticate_agent_with_shared_secret
    else
      doorkeeper_authorize!
      if doorkeeper_token
        @authentication_type = "OAuth"
        @current_agent = Agent.find(doorkeeper_token.resource_owner_id)
      end
    end
  end
end
