class Agents::InvitationsController < Devise::InvitationsController

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
      resource.add_organisation(Organisation.where(id: current_inviter.organisation_ids).find(organisation_id))
      if is_flashing_format? && self.resource.invitation_sent_at
        set_flash_message :notice, :send_instructions, email: self.resource.email
      end
    end
    respond_right_bar_with resource, location: organisation_agents_path(organisation_id)
  end

  protected
  def organisation_id
    devise_parameter_sanitizer.sanitize(:invite)[:organisation_id]
  end

  def invite_params
    devise_parameter_sanitizer.sanitize(:invite).except(:organisation_id)
  end
end
