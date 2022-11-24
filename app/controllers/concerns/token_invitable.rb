# frozen_string_literal: true

# This concern allows to sign in users when a valid invitation token is passed through url params.
# The user will be identified through the token. If the token is linked to a RdvsUser, it will also be
# linked to a rdv.
module TokenInvitable
  extend ActiveSupport::Concern

  included do
    prepend_before_action :handle_invitation_token, if: -> { invitation_token.present? }
  end

  private

  def handle_invitation_token
    store_token_in_session

    return delete_token_from_session_and_redirect(t("devise.invitations.invitation_token_invalid")) \
      if invited_user.blank? && current_user.blank? # we don't check the token if a user is logged in already

    return delete_token_from_session_and_redirect(t("devise.invitations.current_user_mismatch")) \
      if current_user_mismatch?

    return if invited_user.blank? || current_user.present?

    invited_user.only_invited!(rdv: rdv_user_by_token&.rdv)
    sign_in(invited_user, store: false)
  end

  def invitation_token
    invitation_token_param || session[:invitation_token]
  end

  def invitation_token_param
    params[:invitation_token]
  end

  def store_token_in_session
    session[:invitation_token] = invitation_token_param if invitation_token_param.present?
  end

  def current_user_mismatch?
    invited_user.present? && current_user.present? && current_user != invited_user
  end

  def delete_token_from_session_and_redirect(error_msg)
    session.delete(:invitation_token)
    flash[:error] = error_msg
    redirect_to root_path
  end

  def invited_user
    user_by_token || rdv_user_by_token&.user
  end

  def rdv_by_token
    rdv_user_by_token&.rdv
  end

  def user_by_token
    # find_by_invitation_token is a method added by the devise_invitable gem
    @user_by_token ||= User.find_by_invitation_token(session[:invitation_token], true)
  end

  def rdv_user_by_token
    @rdv_user_by_token ||= RdvsUser.find_by_invitation_token(session[:invitation_token], true)
  end
end
