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

    @services = services.order(:name)
    @roles = current_agent.conseiller_numerique? ? [AgentRole::ACCESS_LEVEL_BASIC] : access_levels_collection

    render :new, layout: "application_agent"
  end

  def create
    @services = services.order(:name)
    @roles = current_agent.conseiller_numerique? ? [AgentRole::ACCESS_LEVEL_BASIC] : access_levels_collection

    if agent_params[:email].present?
      create_agent
    else
      create_intervenant
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

    @agent_role = @agent.roles.find_by(organisation: current_organisation)

    access_level = params[:agent][:agent_role][:access_level]

    change_agent_permission_level = ChangeAgentPermissionLevel.new(
      agent: @agent,
      organisation: current_organisation,
      new_access_level: access_level,
      new_email: params[:agent][:email],
      inviting_agent: current_agent
    )

    if change_agent_permission_level.call
      flash[:notice] = change_agent_permission_level.success_message

      if @agent.invitation_accepted_at.blank? && access_level != "intervenant"
        redirect_to admin_organisation_invitations_path(current_organisation)
      else
        redirect_to admin_organisation_agents_path(current_organisation)
      end
    else
      render_edit
    end
  end

  def destroy
    @agent = policy_scope(Agent).find(params[:id])
    was_intervenant = @agent.roles.find_by(organisation: current_organisation).intervenant?
    authorize(@agent)
    removal_service = AgentRemoval.new(@agent, current_organisation)

    if removal_service.remove!
      if @agent.invitation_accepted_at.blank? && !was_intervenant
        redirect_to admin_organisation_invitations_path(current_organisation), notice: removal_service.confirmation_message
      else
        redirect_to admin_organisation_agents_path(current_organisation), notice: removal_service.confirmation_message
      end
    else
      redirect_to edit_admin_organisation_agent_role_path(current_organisation, @agent.role_in_organisation(current_organisation)), flash: { error: removal_service.error_message }
    end
  end

  private

  def render_edit
    @agent_role = @agent.roles.find_by(organisation: current_organisation)
    @agent_removal_presenter = AgentRemovalPresenter.new(@agent, current_organisation)
    render :edit
  end

  def create_agent
    agent = Agent.find_by(email: agent_params[:email].downcase)

    if agent.nil?
      authorize(Agent.new(organisations: [current_organisation])) # Authorize against a dummy Agent

      agent = Agent.invite!(
        email: agent_params[:email],
        uid: agent_params[:email],
        service_id: agent_params[:service_id],
        roles_attributes: [{ organisation: current_organisation, access_level: access_level(agent_params) }]
      )
    else
      new_role = agent.roles.new(
        organisation: current_organisation,
        access_level: access_level(agent_params)
      )
      authorize(new_role) # Checks that the current agent is an admin of the role's organisation
      agent.save(context: :invite) # Specify a different validation context to bypass last_name/first_name presence
      # Warn if the service isn’t the one that was requested
      service = services.find(agent_params[:service_id])

      if agent.service != service
        flash[:error] = I18n.t("activerecord.warnings.models.agent_role.different_service", service: service.name, agent_service: agent.service.name)
      end
    end

    if agent.errors.empty?
      AgentTerritorialAccessRight.find_or_create_by!(agent: agent, territory: current_organisation.territory)
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

  def create_intervenant
    @agent = Agent.new(
      last_name: agent_params[:last_name],
      service_id: agent_params[:service_id],
      roles_attributes: [
        { organisation: current_organisation, access_level: access_level(agent_params) },
      ]
    )
    authorize(@agent)
    if @agent.save
      redirect_to admin_organisation_agents_path(current_organisation), notice: "Intervenant créé avec succès."
    else
      render :new
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

  def access_level(params)
    if current_agent.conseiller_numerique?
      AgentRole::ACCESS_LEVEL_BASIC
    else
      params[:roles_attributes]["0"]["access_level"]
    end
  end

  def agent_params
    params.require(:agent).permit(:email, :service_id, :last_name, roles_attributes: [:access_level])
  end
end
