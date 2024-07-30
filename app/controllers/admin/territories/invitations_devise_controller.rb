class Admin::Territories::InvitationsDeviseController < Devise::InvitationsController
  layout "application_dsfr"

  def new
    @services = current_territory.services
    self.resource = resource_class.new(territories: [current_territory])
    #  authorize_with_legacy_configuration_scope(resource)
    render :new, layout: "application_configuration"
  end

  # Dette technique : ce controller pourrait sans doute reprendre la logique et le service object
  # AdminCreatesAgent utilisé dans Admin::AgentsController
  def create
    agent = Agent.find_by(email: permitted_params[:email].downcase)
    if agent.nil?
      # Authorize against a dummy Agent
      authorize_with_legacy_configuration_scope(Agent.new(permitted_params))
      agent = invite_resource # invite_resource creates the new Agent in DB and sends the invitation.
    else
      agent.save(context: :invite) # Specify a different validation context to bypass last_name/first_name presence
      # Warn if the service isn’t the one that was requested
      flash[:alert] = AdminCreatesAgent.check_agent_service(agent, permitted_params[:service_ids])
    end

    if agent.errors.empty?
      AgentTerritorialAccessRight.find_or_create_by!(agent: agent, territory: current_territory)
      flash[:notice] = if agent.invitation_accepted?
                         I18n.t "activerecord.notice.models.agent_role.existing", email: agent.email
                       else
                         I18n.t "activerecord.notice.models.agent_role.invited", email: agent.email
                       end
      redirect_to admin_territory_agents_path(current_territory)
    else
      # Keep the error message, but redirect instead of just rendering the template:
      # we want a new empty form.
      flash[:error] = agent.errors.full_messages.to_sentence
      redirect_to action: :new
    end
  end

  def pundit_user
    AgentTerritorialContext.new(current_agent, current_territory)
  end

  def current_territory
    @current_territory ||= Territory.find(params[:territory_id])
  end
  helper_method :current_territory

  def policy_scope(*args, **kwargs)
    super([:configuration, *args], **kwargs)
  end
  helper_method :policy_scope

  def authorize_with_legacy_configuration_scope(record, *args, **kwargs)
    super([:configuration, record], *args, **kwargs)
  end

  # invite_params is called by Devise::InvitationsController#invite_resource
  def invite_params
    super.merge(
      # the omniauth uid _is_ the email, always. note: this may be better suited in a hook in agent.rb
      uid: permitted_params[:email],
      allow_blank_name: true
    ).merge(permitted_params)
  end

  def permitted_params
    params.require(:admin_agent).permit(:email, service_ids: [])
  end
end
