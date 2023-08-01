# frozen_string_literal: true

class Admin::AgentRolesController < AgentAuthController
  before_action :set_agent_role, :set_agent_removal_presenter, :set_original_access_level

  def edit
    authorize(@agent_role)
  end

  def update
    authorize(@agent_role)

    if @original_access_level == "intervenant" && agent_role_params[:access_level] != "intervenant"
      process_role_change_from_intervenant
    elsif @original_access_level != "intervenant" && agent_role_params[:access_level] == "intervenant"
      process_role_change_to_intervenant
    else
      process_role_update
    end
  end

  private

  def agent_role_params
    params.require(:agent_role).permit(:access_level)
  end

  def set_agent_role
    @agent_role = AgentRole.find(params[:id])
  end

  def set_original_access_level
    @original_access_level = @agent_role.access_level
  end

  def set_agent_removal_presenter
    @agent_removal_presenter = AgentRemovalPresenter.new(@agent_role.agent, current_organisation)
  end

  def process_role_update
    if @agent_role.update(agent_role_params)
      flash[:notice] = I18n.t "activerecord.notice.models.agent_role.updated"
      redirect_to admin_organisation_agents_path(current_organisation)
    else
      render :edit
    end
  end

  def process_role_change_from_intervenant
    agent = @agent_role.agent
    invitation_email = params[:agent_role][:agent_attributes][:email]
    @agent_role.assign_attributes(agent_role_params)
    if @agent_role.change_role_from_intervenant_and_invite(current_agent, invitation_email)
      flash[:notice] = I18n.t "activerecord.notice.models.agent_role.invited", email: agent.email
      redirect_to admin_organisation_invitations_path(current_organisation)
    else
      render :edit
    end
  end

  def process_role_change_to_intervenant
    @agent_role.assign_attributes(agent_role_params)
    if @agent_role.change_to_intervenant
      flash[:notice] = I18n.t "activerecord.notice.models.agent_role.updated"
      redirect_to admin_organisation_invitations_path(current_organisation)
    else
      render :edit
    end
  end
end
