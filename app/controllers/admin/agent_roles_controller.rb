# frozen_string_literal: true

class Admin::AgentRolesController < AgentAuthController
  before_action :set_agent_role, :set_agent_removal_presenter, :set_original_access_level

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

end
