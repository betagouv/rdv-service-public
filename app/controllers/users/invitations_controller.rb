# frozen_string_literal: true

class Users::InvitationsController < Devise::InvitationsController
  layout "user_registration"

  def invitation; end

  def after_sign_out_path_for(resource_name)
    if request.referer&.end_with?("/invitation")
      return invitations_landing_url
    else
      return root_url
    end
  end

  def edit
    # Reuse prefilled params from the invitation email
    resource.assign_attributes(update_resource_params)
    super
  end
end
