# frozen_string_literal: true

class ChangeAgentPermissionLevel
  def initialize(agent:, organisation:, new_access_level:, agent_params: {})
    @agent = agent
    @organisation = organisation
    @new_access_level = new_access_level.to_s
  end

  def call
    if change_role_to_intervenant?
      process_role_change_to_intervenant
    elsif change_role_from_intervenant?
      process_role_change_from_intervenant
    else
      agent_role.update(access_level: @new_access_level)
    end
  end

  attr_reader :success_message

  private

  def change_role_to_intervenant?
    !agent_role.intervenant? && @new_access_level == "intervenant"
  end

  def change_role_from_intervenant?
    agent_role.intervenant? && @new_access_level != "intervenant"
  end

  def process_role_change_from_intervenant
    agent = @agent_role.agent
    invitation_email = params[:agent_role][:agent_attributes][:email]
    @agent_role.assign_attributes(agent_role_params)
    if @agent_role.change_role_from_intervenant_and_invite(current_agent, invitation_email)
      @success_message = I18n.t("activerecord.notice.models.agent_role.invited", email: agent.email)
    end
  end

  def process_role_change_to_intervenant
    @agent_role.assign_attributes(agent_role_params)
    if @agent_role.change_role_to_intervenant
      @success_message = I18n.t("activerecord.notice.models.agent_role.updated")
    end
  end

  def agent_role
    @agent_role ||= @agent.roles.find_by(organisation: @organisation)
  end
end
