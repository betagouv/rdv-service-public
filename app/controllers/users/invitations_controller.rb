# frozen_string_literal: true

class Users::InvitationsController < Devise::InvitationsController
  layout "user_registration"

  def invitation; end

  def after_sign_out_path_for(resource)
    return invitations_landing_url if request.referer&.end_with?("/invitation")

    super
  end

  def edit
    # Reuse prefilled params from the invitation email
    resource.assign_attributes(update_resource_params)
    super
  end
end
