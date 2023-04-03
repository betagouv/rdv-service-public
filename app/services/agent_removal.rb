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
      @agent.absences.where(organisation: @organisation).each(&:destroy!)
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

  def errors
    I18n.t(".cannot_delete_because_of_rdvs") if upcoming_rdvs?
  end

  def confirm
    if @agent.invitation_accepted_at.blank?
      I18n.t(".invitation_deleted")
    elsif @agent.deleted_at?
      I18n.t(".agent_deleted")
    else
      I18n.t(".agent_removed_from_org")
    end
  end

  alias will_soft_delete? should_soft_delete?
end
