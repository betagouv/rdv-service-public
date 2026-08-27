# This concern allows to sign in users when a valid invitation token is passed through url params.
# If valid the invitation token and params will be stored in the session. The user will then be signed in through the invitation in session.
# If the token is linked to a Participation, it will also be linked to a rdv.
module RestrictedAuthConcern
  extend ActiveSupport::Concern

  included do
    # Pour les routes qui permettent de se connecter, on a besoin d'appeler :store_restricted_auth_token_in_session_and_redirect en premier
    #
    # On utilise un prepend_before_action pour avoir un current_user avant le `authenticate_user!` fait par UserAuthController
    prepend_before_action :sign_in_with_restricted_auth
  end

  def self.user_name_verification_successful!(session)
    session[:restricted_auth] = session.delete(information_for_name_verification).merge(expires_at: 10.minutes.from_now)
  end

  def self.clean_session(session)
    session.delete(:information_for_name_verification)
    session.delete(:restricted_auth)
    session.delete(:rdv_insertion_invitation)
    session.delete(:return_to_after_verification)
  end

  def self.user_to_verify(session)
    User.find(session.dig(:information_for_name_verification, :user_id))
  end

  private

  def store_restricted_auth_token_in_session_and_redirect(allow_rdv_insertion_invitation: false)
    return if params[:invitation_token].blank?

    participation = Participation.find_by(restricted_auth_token: token)

    # Avant mai 2025, on envoyait des notifications avec le contenu de la colonne participations.invitation_token
    # Cette colonne est chiffrée de manière non-réversible (hachée).
    # On fait donc une recherche sur cette colonne avec la méthode find_by_invitation_token, qui est implémentée par la gem devise_invitable
    #
    # Vers mai 2027, on pourra donc supprimer cette ligne, puisque toutes les notifications utilisant
    # la colonne participations.invitation_token seront pour des rdvs qui auront été supprimés.
    participation ||= Participation.find_by_invitation_token(token, true)

    # On vérifie que le token de participation correpond à l'id du rdv dans les params
    # Ça évite qu'un attaquant devine un token de participation puis accède à un rdv sans en connaitre l'id.
    if participation && !ActiveSupport::SecurityUtils.secure_compare(params[:id], participation.rdv_id.to_s)
      return redirect_with_error(t("devise.invitations.invitation_token_invalid"))
    end

    # On connecte l'usager qui a reçu la notification, qui peut être le responsable d'un proche qui participe au rdv
    user = participation&.user&.user_to_notify

    # Si on a un token qui vient d'une invitation de RDV Insertion, on cherche dans la table user
    if allow_rdv_insertion_invitation
      invited_user = User.find_by(rdv_invitation_token: params[:invitation_token])
      user ||= invited_user
    end

    return redirect_with_error(t("devise.invitations.invitation_token_invalid")) if user.blank?
    return redirect_with_error(t("devise.invitations.current_user_mismatch")) if current_user_mismatch?(user)

    if invited_user
      session[:rdv_insertion_invitation] = current_url_params.except(:invitation_token)

      session[:restricted_auth] = { user_id: invited_user.id, expires_at: 10.minutes.from_now }

      redirect_to current_path_without_token
    else
      # L'usager a utilisé un lien avec un token envoyé dans une notification
      # On fait vérifier le début du nom
      session[:information_for_name_verification] = {
        user_id: user.id,
        rdv_id: participation.rdv_id,
      }

      session[:return_to_after_verification] = current_path_without_token

      redirect_to new_users_user_name_initials_verification_path
    end
  end

  def current_path_without_token
    new_params = current_url_params.except(:invitation_token)
    new_params.any? ? "#{request.path}?#{new_params.to_query}" : request.path
  end

  def current_url_params
    Rack::Utils.parse_nested_query(request.query_string).deep_symbolize_keys
  end

  def sign_in_with_restricted_auth
    return if session[:restricted_auth].blank?

    user = User.find_by(id: session.dig(:restricted_auth, :user_id))

    return delete_invitation_from_session_and_redirect(t("devise.invitations.invitation_token_invalid")) if user.blank?
    return delete_invitation_from_session_and_redirect(t("devise.invitations.current_user_mismatch")) if current_user_mismatch?(user)
    return delete_invitation_from_session_and_redirect(t("devise.invitations.session_expired")) if session.dig(:restricted_auth, :expires_at) < Time.zone.now
    return if current_user.present? # no need to sign in if the user is already connected

    user.signed_in_with_invitation_token!(rdv: Rdv.find_by(id: session.dig(:restricted_auth, :rdv_id)))
    sign_in(user, store: false)
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
end
