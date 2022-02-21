# frozen_string_literal: true

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

    return if invited_user.blank?

    invited_user.set_as_invited
    sign_in(invited_user, store: false)
  end

  def invitation_token
    params[:invitation_token] || session[:invitation_token]
  end

  def store_token_in_session
    session[:invitation_token] = params[:invitation_token] if params[:invitation_token].present?
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
    # rubocop:disable Rails/DynamicFindBy
    # find_by_invitation_token is a method added by the devise_invitable gem
    @invited_user ||= User.find_by_invitation_token(session[:invitation_token], true)
    # rubocop:enable Rails/DynamicFindBy
  end
end
