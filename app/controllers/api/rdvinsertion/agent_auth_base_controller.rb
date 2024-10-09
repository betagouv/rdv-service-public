class Api::Rdvinsertion::AgentAuthBaseController < Api::V1::AgentAuthBaseController
  private

  # Cette authentification est faite via un secret partagé avec rdv-insertion qui se trouve
  # dans la variable d'environnement `SHARED_SECRET_FOR_AGENTS_AUTH`.
  # Ainsi nous sommes sûrs ici que les appels authentifiés sont émis par l'application rdv-insertion.
  def authenticate_agent
    authenticate_agent_with_shared_secret
  end
end
