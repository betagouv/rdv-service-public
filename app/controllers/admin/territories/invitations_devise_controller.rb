class Admin::Territories::InvitationsDeviseController < Devise::InvitationsController
  # Ce controller est uniquement utilisé pour permettre aux agents d'accepter les invitations
  layout "application_dsfr"

  # Bloque l'accès aux méthodes du controller parent
  before_action :block_controller_action, except: %i[edit update]

  def block_controller_action
    raise Pundit::NotAuthorizedError, "not authorized"
  end
end
