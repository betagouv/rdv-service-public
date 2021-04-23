class Admin::InvitationsDeviseController < Devise::InvitationsController
  def new
    self.resource = resource_class.new(organisations: [current_organisation])
    authorize(resource)
    render :new, layout: "application_agent"
  end

  def create
    agent = Agent.find_by(email: invite_params[:email].downcase)
    service = Service.find(invite_params[:service_id])
    if agent.nil?
      # Authorize against a dummy Agent
      authorize(Agent.new(invite_params))
      agent = invite_resource # invite_resource creates the new Agent in DB and sends the invitation.
    else
      # Authorize against a new AgentRole
      new_role = agent.roles.new(invite_params[:roles_attributes].values.first)
      authorize(new_role)
      agent.save(context: :invite) # Specify a different validation context to bypass last_name/first_name presence
      # Warn if the service isn’t the one that was requested
      flash[:error] = I18n.t "activerecord.warnings.models.agent_role.different_service", service: service.name, agent_service: agent.service.name if agent.service != service
    end

    if agent.errors.empty?
      if agent.invitation_accepted?
        flash[:notice] = I18n.t "activerecord.notice.models.agent_role.existing", email: agent.email
        redirect_to admin_organisation_agents_path(current_organisation)
      else
        flash[:notice] = I18n.t "activerecord.notice.models.agent_role.invited", email: agent.email
        redirect_to admin_organisation_invitations_path(current_organisation)
      end
    else
      # Keep the error message, but redirect instead of just rendering the template:
      # we want a new empty form.
      flash[:error] = agent.errors.full_messages.to_sentence
      redirect_to action: :new
    end
  end

  protected

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

    # The omniauth uid _is_ the email, always. Note: this may be better suited in a hook in Agent.rb
    params[:uid] = params[:email]

    params
  end
end
