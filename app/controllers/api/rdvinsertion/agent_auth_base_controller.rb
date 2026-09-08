class Api::Rdvinsertion::AgentAuthBaseController < Api::V1::AgentAuthBaseController
  private

  # L'authentification par secret partagé est faite via un secret partagé avec rdv-insertion qui se trouve
  # dans la variable d'environnement `SHARED_SECRET_FOR_AGENTS_AUTH`. Elle a vocation à disparaître.
  # L'authentification par OAuth sera la seule méthode d'authentification valide. Elle n'est autorisée que
  # pour l'application rdv-insertion, dont l'uid est stocké dans la variable d'environnement
  # `RDV_INSERTION_OAUTH_APPLICATION_UID`, afin qu'aucune autre application OAuth ne puisse accéder à ces routes.
  def authenticate_agent
    if request.headers.include?("X-Agent-Auth-Signature")
      authenticate_agent_with_shared_secret
    else
      doorkeeper_authorize!
      return unless doorkeeper_token

      if doorkeeper_token.application.uid == ENV.fetch("RDV_INSERTION_OAUTH_APPLICATION_UID")
        @authentication_type = "OAuth"
        @current_agent = Agent.find(doorkeeper_token.resource_owner_id)
      else
        render(status: :unauthorized, json: {})
      end
    end
  end
end
