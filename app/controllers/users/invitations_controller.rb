class Users::InvitationsController < Devise::InvitationsController
  layout "user_registration"

  def edit
    # Reuse prefilled params from the invitation email
    resource.assign_attributes(update_resource_params)
    super
  end
end
