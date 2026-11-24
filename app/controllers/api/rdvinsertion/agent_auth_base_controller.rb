class Api::Rdvinsertion::AgentAuthBaseController < Api::V1::AgentAuthBaseController
  # Les API réservées à RDV-Insertion ont souvent besoin d'effectuer des opérations
  # d'administration incompatibles avec cette protection.
  # Dans ce contexte, la sécurité est renforcée à travers :
  # - l'usage la restriction ci-dessous impliquant RDV_INSERTION_OAUTH_APPLICATION_UID
  # - les vérifications ajoutées dans #6719
  skip_before_action :detect_param_injection

  # Cette API n'est pas encore prête à ce qu'on ajoute ces vérifications, mais il faudra le faire
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  private

  # L'authentification OAuth n'est autorisée que pour l'application rdv-insertion, dont l'uid est stocké dans la
  # variable d'environnement `RDV_INSERTION_OAUTH_APPLICATION_UID`, afin qu'aucune autre application OAuth ne puisse
  # accéder à ces routes.
  def authenticate_agent
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
