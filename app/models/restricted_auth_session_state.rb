# Cette classe gère l'état de l'authentification restreinte dans la session
class RestrictedAuthSessionState
  def self.authenticate!(session, user_id:)
    session[:restricted_auth] = { user_id:, expires_at: 10.minutes.from_now, authenticated: true }
  end

  def self.prepare_for_name_verification!(session, user_id:, rdv_id:)
    session[:restricted_auth] = { user_id:, rdv_id:, authenticated: false }
  end

  def initialize(session)
    @session = session
  end

  def user_name_verification_successful!
    session[:restricted_auth] = @session[:restricted_auth].merge(expires_at: 10.minutes.from_now, authenticated: true)
  end

  def authenticated?
    @session.dig(:restricted_auth, "authenticated")
  end

  def user
    User.find_by(id: @session.dig(:restricted_auth, "user_id"))
  end

  def rdv
    Rdv.find_by(id: @session.dig(:restricted_auth, "rdv_id"))
  end

  def expired?
    @session.dig(:restricted_auth, "expires_at") < Time.zone.now
  end

  def self.clean_session!(session)
    session.delete(:restricted_auth)
    session.delete(:return_to_after_verification)
  end
end
