class Admin::InvitationsDeviseController < Devise::InvitationsController
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
      flash[:notice] = \
        if resource.invitation_accepted_at.present?
          "L'agent #{resource.email} existait déjà, il a été ajouté à votre organisation"
        else
          "L'agent #{resource.email} a été invité à rejoindre votre organisation"
        end
      redirect_to admin_organisation_invitations_path(current_organisation)
    else
      render :new, layout: "application_agent"
    end
  end

  protected

  def invite_resource
    super do |agent|
      agent.uid = agent.email
    end
  end

  def pundit_user
    AgentContext.new(current_agent, current_organisation)
  end

  def current_organisation
    Organisation.find(params[:organisation_id])
  end
  helper_method :current_organisation

  def policy_scope(*args, **kwargs)
    super([:agent, *args], **kwargs)
  end
  helper_method :policy_scope

  def authorize(*args, **kwargs)
    super([:agent, *args], **kwargs)
  end

  # invite_params is called by Devise::InvitationsController#invite_resource
  def invite_params
    params = devise_parameter_sanitizer.sanitize(:invite)

    # Make sure the agent is being invited for exactly one role
    raise ActionController::BadRequest unless params[:roles_attributes].is_a?(Hash) && params[:roles_attributes].keys == ["0"]

    # Only ever invite to the current organisation
    params[:roles_attributes]["0"][:organisation] = current_organisation

    params
  end
end
