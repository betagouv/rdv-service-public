# This concern allows to sign in users when a valid invitation token is passed through url params.
# If valid the invitation token and params will be stored in the session. The user will then be signed in through the invitation in session.
# If the token is linked to a Participation, it will also be linked to a rdv.
module RestrictedAuthConcern
  extend ActiveSupport::Concern

  included do
    # :store_restricted_auth_token_in_session_and_redirect is called first, :sign_in_with_session_token after it
    prepend_before_action :sign_in_with_session_token
  end

  private

  def store_restricted_auth_token_in_session_and_redirect(store_rdv_insertion_invitation: false)
    return if params[:invitation_token].blank?

    restricted_auth = RestrictedAuth.new(invitation_token: params[:invitation_token])
    return redirect_with_error(t("devise.invitations.invitation_token_invalid")) unless restricted_auth.token_valid?
    return redirect_with_error(t("devise.invitations.current_user_mismatch")) if current_user_mismatch?(restricted_auth.user)

    session[:restricted_auth] = { invitation_token: params[:invitation_token], expires_at: 10.minutes.from_now }

    if store_rdv_insertion_invitation
      session[:rdv_insertion_invitation] = current_url_params.except(:invitation_token)
    end

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
    return true if session[:restricted_auth].blank?

    return delete_invitation_from_session_and_redirect(t("devise.invitations.invitation_token_invalid")) unless restricted_auth.token_valid?
    return delete_invitation_from_session_and_redirect(t("devise.invitations.current_user_mismatch")) if current_user_mismatch?(restricted_auth.user)
    return delete_invitation_from_session_and_redirect(t("devise.invitations.session_expired")) if restricted_auth.expired?
    return if current_user.present? # no need to sign in if the user is already connected

    if User.find_by(rdv_invitation_token: session[:restricted_auth].with_indifferent_access["invitation_token"])
      # On connecte un usager invité via RDV Insertion
      user = restricted_auth.user
      user.signed_in_with_invitation_token!(rdv: restricted_auth.rdv)
      sign_in(user, store: false)
    elsif cookies.encrypted[:"user_name_initials_verified_#{restricted_auth.user.id}"] # rubocop:disable Lint/DuplicateBranch
      # On connecte un usager qui a suivi un lien avec un token et vérifié les trois premières lettres de son nom
      user = restricted_auth.user
      user.signed_in_with_invitation_token!(rdv: restricted_auth.rdv)
      sign_in(user, store: false)
    else
      session[:return_to_after_verification] = request.fullpath
      redirect_to new_users_user_name_initials_verification_path
    end
  end

  def current_user_mismatch?(invited_user)
    current_user.present? && current_user != invited_user
  end

  def delete_invitation_from_session_and_redirect(error_msg)
    session.delete(:restricted_auth)
    redirect_with_error(error_msg)
  end

  def redirect_with_error(error_msg)
    flash[:error] = error_msg
    redirect_to root_path
  end

  def restricted_auth
    @restricted_auth ||= (session[:restricted_auth].present? ? RestrictedAuth.new(**session[:restricted_auth].symbolize_keys) : nil)
  end
end
