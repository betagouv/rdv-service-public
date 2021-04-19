class Users::InvitationsController < Devise::InvitationsController
  layout "user_registration"

  def edit
    # Reuse prefilled params from the invitation email
    resource.assign_attributes(prefilled_params)
    super
  end

  def prefilled_params
    params.permit(:first_name, :last_name, :phone_number)
  end
end
