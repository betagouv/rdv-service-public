class Agents::InvitationsController < Devise::InvitationsController

  respond_to :html, :json

  def new
    self.resource = resource_class.new
    respond_right_bar_with resource
  end

  def create
    @agent = Agent.create(invite_params)
    unless resource_class == Agent && @agent.errors[:email].empty?
      @agent.errors.delete(:password)
      return respond_right_bar_with @agent, location: organisation_agents_path(organisation_id)
    end
    self.resource = Agent.find_by(email: invite_params[:email]) || invite_resource
    yield resource if block_given?
    org_to_add = Organisation.where(id: current_inviter.organisation_ids).find(organisation_id)
    resource.organisations << org_to_add unless resource.organisations.include?(org_to_add)
    resource.save(validate: false)
    set_flash_message :notice, :send_instructions, email: resource.email if resource.errors.empty?
    redirect_to organisation_agents_path(organisation_id)
  end

  protected
  def organisation_id
    devise_parameter_sanitizer.sanitize(:invite)[:organisation_id]
  end

  def invite_params
    devise_parameter_sanitizer.sanitize(:invite).except(:organisation_id)
  end
end
