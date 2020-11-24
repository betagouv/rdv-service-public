class Admin::InvitationsController < Devise::InvitationsController
  respond_to :html

  def new
    self.resource = resource_class.new(organisations: [current_organisation])
    authorize(resource)
    render :new, layout: "application_agent"
  end

  def create
    agent = Agent.find_by(email: invite_params[:email].downcase)
    if agent.nil?
      self.resource = invite_resource
    else
      self.resource = agent
      agent.add_organisation(current_organisation)
    end
    authorize(resource)
    if resource.errors.empty?
      set_flash_message :notice, :send_instructions, email: resource.email
      redirect_to admin_organisation_agents_path(organisation_id)
    else
      render :new, layout: "application_agent"
    end
  end

  protected

  def invite_resource
    super do |agent|
      agent.uid = agent.email
      agent.organisations = [current_organisation]
    end
  end

  def pundit_user
    AgentContext.new(current_agent, current_organisation)
  end

  def current_organisation
    Organisation.find(params[:organisation_id]) if params[:organisation_id]
  end
  helper_method :current_organisation

  def policy_scope(*args, **kwargs)
    super([:agent, *args], **kwargs)
  end
  helper_method :policy_scope

  def authorize(*args, **kwargs)
    super([:agent, *args], **kwargs)
  end

  def organisation_id
    devise_parameter_sanitizer.sanitize(:invite)[:organisation_id]
  end

  def invite_params
    devise_parameter_sanitizer.sanitize(:invite).except(:organisation_id)
  end
end
