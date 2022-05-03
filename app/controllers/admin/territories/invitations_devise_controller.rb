# frozen_string_literal: true

class Admin::Territories::InvitationsDeviseController < Devise::InvitationsController
  def new
    @services = Service.all
    self.resource = resource_class.new(territories: [current_territory])
    #  authorize(resource)
    render :new, layout: "application_configuration"
  end

  def create
    # invite_resource creates the new Agent in DB and sends the invitation.
    if (agent = invite_resource)
      authorize(Agent.new(invite_params))
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

  def authorize(*args, **kwargs)
    super([:configuration, *args], **kwargs)
  end

  # invite_params is called by devise::invitationscontroller#invite_resource
  def invite_params
    params = devise_parameter_sanitizer.sanitize(:invite)

    # remove not accessible organisation
    params[:roles_attributes].delete_if do |role_attributes|
      params[:roles_attributes][role_attributes]["level"] == "none"
    end

    # Organisation's admin is allowed to invite agents
    allow_to_invite_agents = params[:roles_attributes].any? { |t| t[1]["level"] == "admin" }

    # only ever invite to the current territory
    params.merge!({ agent_territorial_access_rights_attributes: [{ territory_id: current_territory.id, allow_to_invite_agents: allow_to_invite_agents }] })

    # the omniauth uid _is_ the email, always. note: this may be better suited in a hook in agent.rb
    params[:uid] = params[:email]

    params
  end
end
