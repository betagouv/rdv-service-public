class Common::InvitationsController < Devise::InvitationsController
  respond_to :html, :json

  def new
    self.resource = resource_class.new
    respond_right_bar_with resource
  end

  def create
    self.resource = invite_resource
    resource_invited = resource.errors.empty?

    yield resource if block_given?

    if resource_invited
      if is_flashing_format? && resource.invitation_sent_at
        set_flash_message :notice, :send_instructions, email: resource.email
      end
      if method(:after_invite_path_for).arity == 1
        respond_right_bar_with resource, location: after_invite_path_for(current_inviter)
      else
        respond_right_bar_with resource, location: after_invite_path_for(current_inviter, resource)
      end
    else
      respond_right_bar_with resource
    end
  end
end
