# This concern allows to sign in users when a valid invitation token is passed through url params.
# If valid the invitation token and params will be stored in the session. The user will then be signed in through the invitation in session.
# If the token is linked to a Participation, it will also be linked to a rdv.
module TokenInvitable
  extend ActiveSupport::Concern

  included do
    # :store_invitation_in_session_and_redirect is called first, :sign_in_with_session_token after it
    prepend_before_action :sign_in_with_session_token, if: -> { session[:invitation].present? }
    prepend_before_action :store_invitation_in_session_and_redirect, if: -> { params[:invitation_token].present? }
  end

  private

  def store_invitation_in_session_and_redirect
    invitation = Invitation.new(current_url_params)
    return redirect_with_error(t("devise.invitations.invitation_token_invalid")) unless invitation.token_valid?
    return redirect_with_error(t("devise.invitations.current_user_mismatch")) if current_user_mismatch?(invitation.user)

    session[:invitation] = current_url_params.merge(expires_at: 10.minutes.from_now)

    redirect_to current_path_without_token
  end

  def current_path_without_token
    new_params = current_url_params.except(:invitation_token)
    new_params.any? ? "#{request.path}?#{new_params.to_query}" : request.path
  end

  def current_url_params
    Rack::Utils.parse_nested_query(request.query_string).deep_symbolize_keys
  end

  def sign_in_with_session_token
    return delete_invitation_from_session_and_redirect(t("devise.invitations.invitation_token_invalid")) unless invitation.token_valid?
    return delete_invitation_from_session_and_redirect(t("devise.invitations.current_user_mismatch")) if current_user_mismatch?(invitation.user)
    return delete_invitation_from_session_and_redirect(t("devise.invitations.session_expired")) if invitation.expired?
    return if current_user.present? # no need to sign in if the user is already connected

    user = invitation.user
    user.signed_in_with_invitation_token!(rdv: invitation.rdv)
    sign_in(user, store: false)
  end

  def current_user_mismatch?(invited_user)
    current_user.present? && current_user != invited_user
  end

  def delete_invitation_from_session_and_redirect(error_msg)
    session.delete(:invitation)
    redirect_with_error(error_msg)
  end

  def redirect_with_error(error_msg)
    flash[:error] = error_msg
    redirect_to root_path
  end

  def invitation
    @invitation ||= (session[:invitation].present? ? Invitation.new(session[:invitation]) : nil)
  end
end
