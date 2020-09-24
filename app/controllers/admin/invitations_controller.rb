class Admin::InvitationsController < Devise::InvitationsController
  respond_to :html, :json

  def new
    self.resource = resource_class.new
    respond_right_bar_with resource
  end

  def create
    agent = Agent.find_by(email: invite_params[:email].downcase)
    self.resource = agent.nil? ? invite_resource : agent
    resource_invited = resource.errors.empty?
    if resource_invited
      resource.add_organisation(Organisation.where(id: current_inviter.organisation_ids).find(organisation_id))
      set_flash_message :notice, :send_instructions, email: resource.email
    end
    respond_right_bar_with resource, location: admin_organisation_agents_path(organisation_id)
  end

  protected

  def pundit_user
    AgentContext.new(current_agent)
  end

  def organisation_id
    devise_parameter_sanitizer.sanitize(:invite)[:organisation_id]
  end

  def invite_params
    devise_parameter_sanitizer.sanitize(:invite).except(:organisation_id)
  end
end
