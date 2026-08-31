# Cette classe gère l'état de l'authentification restreinte dans la session
class RestrictedAuthSessionState
  def self.authenticate!(session, user_id:)
    session[:restricted_auth] = { user_id:, expires_at: 10.minutes.from_now, authenticated: true }
  end

  def self.prepare_for_name_verification!(session, user_id:, rdv_id:)
    session[:restricted_auth] = { user_id:, rdv_id:, authenticated: false }
  end

  def self.clean_session!(session)
    session.delete(:restricted_auth)
    session.delete(:return_to_after_verification)
  end

  def initialize(session)
    @session = session
  end

  def user_name_verification_successful!
    @session[:restricted_auth] = @session[:restricted_auth].merge(expires_at: 10.minutes.from_now, authenticated: true)
  end

  def authenticated?
    restricted_auth_hash[:authenticated]
  end

  def user
    User.find_by(id: restricted_auth_hash[:user_id])
  end

  def rdv
    Rdv.find_by(id: restricted_auth_hash[:rdv_id])
  end

  def expired?
    restricted_auth_hash[:expires_at] < Time.zone.now
  end

  private

  def restricted_auth_hash
    # Quand on déserialise la session, les clés deviennent des strings alors qu'on utilise des symboles pour les écrire
    @session[:restricted_auth]&.with_indifferent_access || {}
  end
end
