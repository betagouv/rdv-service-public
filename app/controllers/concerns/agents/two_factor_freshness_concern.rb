module Agents::TwoFactorFreshnessConcern
  extend ActiveSupport::Concern

  FRESHNESS_WINDOW = 30.minutes
  SESSION_KEY = :agent_2fa_verified_at
  RETURN_TO_SESSION_KEY = :two_factor_step_up_return_to

  def two_factor_fresh?
    verified_at = session[SESSION_KEY]
    verified_at.present? && Time.zone.parse(verified_at) > FRESHNESS_WINDOW.ago
  end

  def mark_two_factor_verified!
    session[SESSION_KEY] = Time.zone.now.iso8601
  end

  def require_recent_two_factor_authentication!
    return if two_factor_fresh?

    session[RETURN_TO_SESSION_KEY] = request.fullpath
    redirect_to new_agents_two_factor_verification_path
  end
end
