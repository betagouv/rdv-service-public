class Agents::SessionsController < Devise::SessionsController
  before_action :exclude_signed_in_users, only: [:new]

  def create
    checker = PasswordChecker.new(params[:agent][:password]) # voir aussi app/controllers/users/sessions_controller.rb
    if checker.too_weak?
      flash[:error] =
        "Votre mot de passe est trop faible, vous devez le mettre à jour pour continuer d'utiliser #{current_domain.name}. <a href=\"#{edit_agent_mot_de_passes_path}\">Changer de mot de passe</a>"
    end

    super
  end

  private

  def exclude_signed_in_users
    return true unless user_signed_in?

    redirect_to(
      root_path,
      flash: { error: "Déconnectez-vous d'abord de votre compte usager pour vous connecter en tant qu'agent" }
    )
  end
end
