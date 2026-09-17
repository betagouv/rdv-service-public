class Admin::Territories::InvitationsDeviseController < Devise::InvitationsController
  # Ce controller est uniquement utilisé pour permettre aux agents d'accepter les invitations
  layout "application_agent_config"

  # Bloque l'accès aux méthodes du controller parent pour éviter de permettre d'envoyer des invitations n'importe comment
  before_action :block_controller_action, except: %i[edit update] # rubocop:disable Rails/LexicallyScopedActionFilter
  # Quand ProConnect est disponible, la création de compte par mot de passe est désactivée y compris via un POST direct
  before_action :block_password_signup_when_pro_connect_available, only: :update # rubocop:disable Rails/LexicallyScopedActionFilter

  def block_controller_action
    raise Pundit::NotAuthorizedError, "not authorized"
  end

  def block_password_signup_when_pro_connect_available
    raise Pundit::NotAuthorizedError, "not authorized" if helpers.display_pro_connect_button?
  end
end
