class Admin::Territories::InvitationsDeviseController < Devise::InvitationsController
  # Ce controller est uniquement utilisé pour permettre aux agents d'accepter les invitations
  layout "application_agent_config"

  # Bloque l'accès aux méthodes du controller parent pour éviter de permettre d'envoyer des invitations n'importe comment
  before_action :block_controller_action, except: %i[edit update] # rubocop:disable Rails/LexicallyScopedActionFilter
  # Quand ProConnect est disponible, la création de compte admin par mot de passe est désactivée y compris via un POST direct
  before_action :block_admin_password_signup_when_pro_connect_available, only: :update # rubocop:disable Rails/LexicallyScopedActionFilter

  def block_controller_action
    raise Pundit::NotAuthorizedError, "not authorized"
  end

  def block_admin_password_signup_when_pro_connect_available
    return unless helpers.display_pro_connect_button?

    raw_invitation_token = params.dig(:agent, :invitation_token) || params[:invitation_token]
    invited_agent = raw_invitation_token && Agent.find_by_invitation_token(raw_invitation_token, true)
    return unless invited_agent&.roles&.access_level_admin&.any?

    raise Pundit::NotAuthorizedError, "not authorized"
  end
end
