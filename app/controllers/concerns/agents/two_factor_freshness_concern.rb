module Agents::TwoFactorFreshnessConcern
  extend ActiveSupport::Concern

  FRESHNESS_WINDOW = 30.minutes
  SESSION_KEY = :agent_2fa_verified_at
  RETURN_TO_SESSION_KEY = :two_factor_step_up_return_to
  # Un fichier envoyé via `send_data` ne remplace pas la page affichée par le navigateur (pas de
  # rendu HTML) : rediriger directement vers ce lien laisse l'agent sur la page de vérification du
  # code. On redirige donc vers la liste des exports, qui se charge de relancer le téléchargement.
  EXPORT_DOWNLOAD_PATH_PATTERN = %r{\A/agents/exports/([0-9a-f-]+)/download\z}

  def two_factor_fresh?
    verified_at = session[SESSION_KEY]
    verified_at.present? && Time.zone.parse(verified_at) > FRESHNESS_WINDOW.ago
  end

  def mark_two_factor_verified!
    session[SESSION_KEY] = Time.zone.now.iso8601
  end

  # `sign_out` ne vide pas la session Rails (seules les clés Warden sont retirées) : sans cet appel,
  # la fraîcheur du 2FA survivrait à la déconnexion et pourrait profiter à un autre agent se
  # connectant ensuite depuis le même navigateur.
  def clear_two_factor_freshness!
    session.delete(SESSION_KEY)
    session.delete(RETURN_TO_SESSION_KEY)
  end

  # Un super admin usurpant un agent n'a accès ni à sa boîte mail, ni à son compte ProConnect : lui
  # demander le 2FA de l'agent le bloquerait. Sa propre connexion en tant que super admin a déjà
  # nécessité un 2FA récent (cf. `ProConnectController#connect_super_admin`) et sa session est bornée
  # dans le temps (cf. le timeout Devise sur les sessions SuperAdmin), donc on peut l'exempter ici.
  # Idéalement on rajoutera la vérification du 2FA récent du SuperAdmin dans un second temps.
  def require_recent_two_factor_authentication!
    return if session[:super_admin_signed_in_as_agent]
    return if two_factor_fresh?

    session[RETURN_TO_SESSION_KEY] = request.fullpath
    redirect_to new_agents_two_factor_verification_path
  end

  def redirect_after_two_factor_verification!(return_to)
    match = return_to&.match(EXPORT_DOWNLOAD_PATH_PATTERN)

    if match
      redirect_to agents_exports_path(auto_download_export_id: match[1])
    else
      redirect_to return_to || agents_exports_path
    end
  end
end
