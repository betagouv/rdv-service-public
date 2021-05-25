class Users::InvitationsController < Devise::InvitationsController
  layout "user_registration"

  def invitation; end

  def resource_from_invitation_token
    unless params[:invitation_token] && self.resource = resource_class.find_by_invitation_token(params[:invitation_token], true)
      set_flash_message(:alert, :invitation_token_invalid) if is_flashing_format?
      request.referer.end_with?("/invitation") ? (redirect_to invitations_landing_url) : (redirect_to after_sign_out_path_for(resource_name))
    end
  end

  def edit
    # Reuse prefilled params from the invitation email
    resource.assign_attributes(update_resource_params)
    super
  end
end
