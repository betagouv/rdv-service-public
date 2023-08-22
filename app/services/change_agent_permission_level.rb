# frozen_string_literal: true

class ChangeAgentPermissionLevel
  def initialize(agent:, organisation:, new_access_level:, agent_params:, inviting_agent:)
    @agent = agent
    @organisation = organisation
    @new_access_level = new_access_level.to_s
    @agent_params = agent_params
    @inviting_agent = inviting_agent
  end

  def call
    if change_role_from_intervenant?
      turn_intervenant_into_agent_with_account
    elsif change_role_to_intervenant?
      turn_agent_with_account_into_intervenant
    else
      agent_role.update(access_level: @new_access_level)
    end
  end

  attr_reader :success_message, :new_access_level

  private

  def change_role_to_intervenant?
    !agent_role.intervenant? && @new_access_level == "intervenant"
  end

  def change_role_from_intervenant?
    agent_role.intervenant? && @new_access_level != "intervenant"
  end

  def turn_intervenant_into_agent_with_account
    assign_agent_and_role_attributes
    if @agent.save
      @agent.confirm
      @agent.invite!(@inviting_agent)
      @success_message = I18n.t("activerecord.notice.models.agent_role.invited", email: @agent.email)
      true
    end
  end

  def assign_agent_and_role_attributes
    # Devise va essayer de confirmer l'agent car il y a un changement d'email hors on passe d'agent à intervenant, d'un email nil à un email d'invitation.
    # On skip donc la confirmation car on souhaite l'inviter
    @agent.skip_confirmation_notification!
    @agent.skip_last_name_and_first_name_validation = true
    @agent.assign_attributes(@agent_params)
    @agent.assign_attributes(roles_attributes: {
                               id: agent_role.id,
                               access_level: @new_access_level,
                             })
  end

  def turn_agent_with_account_into_intervenant
    if @agent.organisations.count > 1
      @agent.errors.add(:base, "Un agent membre de plusieurs organisations ne peut pas avoir un statut d'intervenant")
      return false
    end

    reset_agent_email_and_password
    reset_agent_invitation_fields
    @agent.assign_attributes(first_name: nil)
    @agent.assign_attributes(roles_attributes: {
                               id: agent_role.id,
                               access_level: @new_access_level,
                             })
    if @agent.save
      @success_message = I18n.t("activerecord.notice.models.agent_role.updated")
    end
  end

  def reset_agent_email_and_password
    @agent.email = nil
    @agent.uid = nil
    @agent.password = nil
    @agent.password_confirmation = nil
  end

  def reset_agent_invitation_fields
    @agent.invitation_token = nil
    @agent.invitation_accepted_at = nil
    @agent.invitation_created_at = nil
    @agent.invitation_sent_at = nil
    @agent.invited_by_id = nil
    @agent.invited_by_type = nil
  end

  def agent_role
    @agent_role ||= @agent.roles.find_by(organisation: @organisation)
  end
end
