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

  def authenticate_agent_with_shared_secret
    if shared_secret_is_valid?
      @current_agent = Agent.find_by(email: request.headers["uid"])
      @authentication_type = "SharedSecret"
    else
      Sentry.capture_message("API authentication agent was called with an invalid signature !", fingerprint: ["api_agent_invalid_sig"])
      render(
        status: :unauthorized,
        json: {
          errors: [I18n.t("devise.failure.unauthenticated")],
        }
      )
    end
  end

  def shared_secret_is_valid?
    return false if request.headers["X-Agent-Auth-Signature"].nil?

    agent = Agent.find_by(email: request.headers["uid"])
    # Structure of the payload need to be exact for digest comparison
    payload = {
      id: agent.id,
      first_name: agent.first_name,
      last_name: agent.last_name,
      email: agent.email,
    }

    ActiveSupport::SecurityUtils.secure_compare(
      OpenSSL::HMAC.hexdigest("SHA256", ENV.fetch("SHARED_SECRET_FOR_AGENTS_AUTH"), payload.to_json),
      request.headers["X-Agent-Auth-Signature"]
    )
  end
end
