class Admin::Territories::InvitationsDeviseController < Devise::InvitationsController
  # Ce controller est uniquement utilisé pour permettre aux agents d'accepter les invitations
  layout "application_dsfr"
end
