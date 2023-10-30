class Invitation
  attr_reader :attributes

  def initialize(attributes)
    @attributes = attributes.deep_symbolize_keys
  end

  def expires_at
    @attributes[:expires_at]
  end

  def token
    @attributes[:invitation_token]
  end

  def query_params
    @attributes.except(:invitation_token, :expires_at)
  end

  def user
    user_by_rdv_invitation_token || rdvs_user_by_invitation_token&.user&.user_to_notify
  end

  def rdv
    rdvs_user_by_invitation_token&.rdv
  end

  def token_valid?
    user.present?
  end

  def to_take_rdv?
    user_by_rdv_invitation_token.present?
  end

  def to_edit_rdv?
    rdvs_user_by_invitation_token.present?
  end

  def expired?
    expires_at.blank? || expires_at < Time.zone.now
  end

  def user_by_rdv_invitation_token
    @user_by_rdv_invitation_token ||= token.present? ? User.find_by(rdv_invitation_token: token) : nil
  end

  def rdvs_user_by_invitation_token
    # find_by_invitation_token is a method added by the devise_invitable gem
    @rdvs_user_by_invitation_token ||= token.present? ? RdvsUser.find_by_invitation_token(token, true) : nil
  end
end
