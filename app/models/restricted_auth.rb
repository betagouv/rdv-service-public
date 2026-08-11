class Invitation
  def initialize(invitation_token:, expires_at: nil)
    @token = invitation_token
    @expires_at = expires_at
  end

  attr_reader :token, :expires_at

  def user
    user_by_rdv_invitation_token || participation_by_invitation_token&.user&.user_to_notify
  end

  def rdv
    participation_by_invitation_token&.rdv
  end

  def token_valid?
    user.present?
  end

  def expired?
    expires_at.blank? || expires_at < Time.zone.now
  end

  private

  def user_by_rdv_invitation_token
    @user_by_rdv_invitation_token ||= token.present? ? User.find_by(rdv_invitation_token: token) : nil
  end

  def participation_by_invitation_token
    return nil if token.blank?

    # find_by_invitation_token is a method added by the devise_invitable gem
    @participation_by_invitation_token ||= Participation.find_by_invitation_token(token, true)

    @participation_by_invitation_token ||= Participation.find_by(restricted_auth_token: token)
  end
end
