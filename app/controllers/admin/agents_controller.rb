# frozen_string_literal: true

class Admin::AgentsController < AgentAuthController
  respond_to :html, :json

  def index
    @agents = policy_scope(Agent)
      .includes(:service, :roles, :organisations)
      .active

    @agents = @agents.joins(:organisations).where(organisations: { id: current_organisation.id }) if current_organisation
    @invited_agents_count = @agents.invitation_not_accepted.created_by_invite.count

    @agents = @agents.not_intervenants.complete.or(@agents.intervenants)
    @agents = index_params[:term].present? ? @agents.search_by_text(index_params[:term]) : @agents.order_by_last_name
    @agents = @agents.page(params[:page])
  end

  def new
    @agent = Agent.new(organisations: [current_organisation])
    authorize(@agent)

    render_new
  end

  def create
    authorize(Agent.new(organisations: [current_organisation]))

    create_agent = CreateAgent.new(
      agent_params,
      current_agent,
      current_organisation,
      access_level
    )

    @agent = create_agent.call

    if @agent.valid?
      flash[:notice] = create_agent.confirmation_message
      flash[:error] = create_agent.warning_message
      redirect_to index_path_for(@agent)
    else
      render_new
    end
  end

  def edit
    @agent = Agent.find(params[:id])
    authorize(@agent)

    render_edit
  end

  def update
    @agent = Agent.find(params[:id])
    authorize(@agent)

    change_agent_permission_level = ChangeAgentPermissionLevel.new(
      agent: @agent,
      organisation: current_organisation,
      new_access_level: params[:agent][:agent_role][:access_level],
      new_email: params[:agent][:email],
      inviting_agent: current_agent
    )

    if change_agent_permission_level.call
      flash[:notice] = change_agent_permission_level.success_message

      redirect_to index_path_for(@agent)
    else
      render_edit
    end
  end

  def destroy
    @agent = policy_scope(Agent).find(params[:id])
    authorize(@agent)

    removal_service = AgentRemoval.new(@agent, current_organisation)

    if removal_service.remove!
      flash[:notice] = removal_service.confirmation_message

      redirect_to index_path_for(@agent)
    else
      redirect_to edit_admin_organisation_agent_path(current_organisation, @agent), flash: { error: removal_service.error_message }
    end
  end

  private

  def render_new
    @services = services.order(:name)
    @roles = current_agent.conseiller_numerique? ? [AgentRole::ACCESS_LEVEL_BASIC] : access_levels_collection
    @agent_role = AgentRole.new

    render :new, layout: "application_agent"
  end

  def render_edit
    @agent_role = @agent.roles.find_by(organisation: current_organisation)
    @agent_removal_presenter = AgentRemovalPresenter.new(@agent, current_organisation)
    @roles = current_agent.conseiller_numerique? ? [AgentRole::ACCESS_LEVEL_BASIC] : access_levels_collection

    render :edit
  end

  def index_path_for(agent)
    if agent.invitation_sent_at? && !agent.invitation_accepted?
      admin_organisation_invitations_path(current_organisation)
    else
      admin_organisation_agents_path(current_organisation)
    end
  end

  def services
    Agent::ServicePolicy::AdminScope.new(pundit_user, Service).resolve
  end

  def index_params
    @index_params ||= params.permit(:term, :intervenant_term)
  end

  def access_levels_collection
    if activate_intervenants_feature?
      AgentRole::ACCESS_LEVELS_WITH_INTERVENANT
    else
      AgentRole::ACCESS_LEVELS
    end
  end

  def activate_intervenants_feature?
    # For CDAD Expe
    current_organisation.territory_id == 59 ||
      Rails.env.development? ||
      Rails.env.test? ||
      ENV["RDV_SOLIDARITES_INSTANCE_NAME"] == "DEMO"
  end

  def access_level
    if @current_agent.conseiller_numerique?
      AgentRole::ACCESS_LEVEL_BASIC
    else
      params[:agent][:agent_role][:access_level]
    end
  end

  def agent_params
    params.require(:agent).permit(:email, :service_id, :last_name)
  end
end
