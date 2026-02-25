class Users::InvitationsController < Devise::InvitationsController
  # Ce controller est conservé uniquement pour rediriger les vieilles URLs d'invitation Devise
  # qui pourraient traîner dans des boîtes mail.
  # À supprimer lors du retrait du module Devise :invitable sur User.
  layout "application_narrow"

  before_action :redirect_to_sign_in

  private

  def redirect_to_sign_in
    redirect_to new_user_session_path, notice: "Connectez-vous avec votre code à 6 chiffres."
  end
end
