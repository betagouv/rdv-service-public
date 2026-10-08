# Ce module gère la fraîcheur de la double authentification de l'agent dans la session
module AgentTwoFactorSessionState
  FRESHNESS_WINDOW = 30.minutes
  SESSION_KEY = :agent_2fa_verified_at
  RETURN_TO_SESSION_KEY = :two_factor_verification_return_to

  class << self
    def fresh?(session)
      verified_at = session[SESSION_KEY]
      verified_at.present? && Time.zone.parse(verified_at) > FRESHNESS_WINDOW.ago
    end

    def mark_verified!(session)
      session[SESSION_KEY] = Time.zone.now.iso8601
    end

    def store_return_to!(session, path)
      session[RETURN_TO_SESSION_KEY] = path
    end

    # Un fichier envoyé via `send_data` ne remplace pas la page affichée par le navigateur (pas de
    # rendu HTML) : rediriger directement vers ce lien laisserait l'agent sur la page de vérification
    # du code, sans retour visuel. On renvoie donc vers la liste des exports, où l'agent peut relancer
    # lui-même le téléchargement.
    def pop_return_to!(session)
      return_to = session.delete(RETURN_TO_SESSION_KEY)
      return Rails.application.routes.url_helpers.agents_exports_path if return_to.blank? || export_download_path?(return_to)

      return_to
    end

    # `sign_out` ne vide pas la session Rails (seules les clés Warden sont retirées) : sans cet appel,
    # la fraîcheur du 2FA survivrait à la déconnexion et pourrait profiter à un autre agent se
    # connectant ensuite depuis le même navigateur.
    def clear!(session)
      session.delete(SESSION_KEY)
      session.delete(RETURN_TO_SESSION_KEY)
    end

    private

    def export_download_path?(path)
      route = Rails.application.routes.recognize_path(path)
      route[:controller] == "agents/exports" && route[:action] == "download"
    rescue ActionController::RoutingError
      false
    end
  end
end
