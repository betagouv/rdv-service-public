# Ce module gère la fraîcheur de la double authentification de l'agent dans la session
module AgentTwoFactorSessionState
  FRESHNESS_WINDOW = 30.minutes
  SESSION_KEY = :agent_2fa_verified_at
  RETURN_TO_SESSION_KEY = :two_factor_verification_return_to

  class << self
    def recent_2fa?(session)
      # Un super admin usurpant un agent n'a accès ni à sa boîte mail, ni à son compte ProConnect.
      # Idéalement on rajoutera la vérification du 2FA récent du SuperAdmin dans un second temps.
      return true if session[:super_admin_signed_in_as_agent]

      verified_at = session[SESSION_KEY]
      verified_at.present? && Time.zone.parse(verified_at) > FRESHNESS_WINDOW.ago
    end

    def mark_verified!(session)
      session[SESSION_KEY] = Time.zone.now.iso8601
    end

    def store_return_to!(session, path)
      session[RETURN_TO_SESSION_KEY] = path
    end

    def pop_return_to!(session)
      session.delete(RETURN_TO_SESSION_KEY).presence || Rails.application.routes.url_helpers.authenticated_agent_root_path
    end

    # `sign_out` ne vide pas la session Rails (seules les clés Warden sont retirées) : sans cet appel,
    # la fraîcheur du 2FA survivrait à la déconnexion et pourrait profiter à un autre agent se
    # connectant ensuite depuis le même navigateur.
    def clear!(session)
      session.delete(SESSION_KEY)
      session.delete(RETURN_TO_SESSION_KEY)
    end
  end
end
