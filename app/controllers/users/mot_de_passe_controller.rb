# Contrairement au User::PasswordsController qui gère les reset de mot de passe via les mécanismes custom de devise
# et qui ne nécessite pas que l'usager soit connecté,
# ce controller gère la modification de mot de passe pour un usager connecté, sans utiliser Devise.
class Users::MotDePasseController < UserAuthController
  def edit
    authorize current_user
  end

  def update
    authorize current_user
    if current_user.update_with_password(user_params)
      # bypass_sign_in(current_user) # Pour des raisons mystérieuses, Devise déconnecte l'agent après un changement de mot de passe
      flash[:notice] = "Votre mot de passe a été changé"
      redirect_to edit_user_registration_path
    else
      render :edit
    end
  end
end
