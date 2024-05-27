# Contrairement au User::PasswordsController qui gère les reset de mot de passe via les mécanismes custom de devise
# et qui ne nécessite pas que l'usager soit connecté,
# ce controller gère la modification de mot de passe pour un usager connecté, sans utiliser Devise.
class Users::MotDePasseController < UserAuthController
  end
end
