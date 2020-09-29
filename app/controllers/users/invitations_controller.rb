class Users::InvitationsController < Devise::InvitationsController
  layout "user_registration"

  def edit
    super
  end
end
