# frozen_string_literal: true

class AgentRemoval
  def initialize(agent, organisation)
    @agent = agent
    @organisation = organisation
  end

  def remove!
    return false if upcoming_rdvs?

    Agent.transaction do
      @agent.roles.find_by(organisation: @organisation).destroy!
      @agent.absences.each(&:destroy!) if should_soft_delete?
      @agent.plage_ouvertures.where(organisation: @organisation).each(&:destroy!)
      @agent.soft_delete if should_soft_delete?
      true
    end
  end

  def upcoming_rdvs?
    @upcoming_rdvs ||= @agent.rdvs.where(organisation: @organisation).future.not_cancelled.any?
  end

  def should_soft_delete?
    (@agent.organisations - [@organisation]).empty?
  end

  def error_message
    I18n.t("admin.territories.agent_roles.destroy.cannot_delete_because_of_rdvs") if upcoming_rdvs?
  end

  def confirmation_message
    if @agent.invitation_accepted_at.blank?
      I18n.t("admin.territories.agent_roles.destroy.invitation_deleted")
    elsif @agent.deleted_at?
      I18n.t("admin.territories.agent_roles.destroy.agent_deleted")
    else
      I18n.t("admin.territories.agent_roles.destroy.agent_removed_from_org")
    end
  end

  alias will_soft_delete? should_soft_delete?
end
