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
    authorize_with_legacy_configuration_scope(Agent.new(permitted_params))

    create_agent = AdminCreatesAgent.new(
      agent_params: permitted_params,
      current_agent: current_agent,
      organisation_ids: params.require(:admin_agent).require(:organisation_ids),
      access_level: AgentRole::ACCESS_LEVEL_BASIC
    )

    @agent = create_agent.call

    if @agent.valid?
      flash[:notice] = create_agent.confirmation_message
      flash[:alert] = create_agent.warning_message
      redirect_to admin_territory_agents_path(current_territory)
    else
      flash[:error] = agent.errors.full_messages.to_sentence
      render_new
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
    authorize([:configuration, record], *args, **kwargs)
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
