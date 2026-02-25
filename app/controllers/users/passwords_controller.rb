class Users::PasswordsController < Devise::PasswordsController
  # Ce controller est conservé uniquement pour rediriger les vieilles URLs de reset de mot de passe
  # (tokens expirés après 6h, donc sans impact fonctionnel).
  # À supprimer lors du retrait du module Devise :recoverable sur User.
  layout "application_narrow"

  def new
    redirect_to new_user_session_path
  end

  def create
    redirect_to new_user_session_path
  end

  def edit
    redirect_to new_user_session_path
  end

  def update
    redirect_to new_user_session_path
  end
end
