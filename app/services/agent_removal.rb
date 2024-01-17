class AgentRemoval
  include ActiveModel::Validations

  validate :no_upcoming_rdv

  def initialize(agent, organisation)
    @agent = agent
    @organisation = organisation
  end

  def remove!
    raise errors.full_messages.join if invalid?

    Agent.transaction do
      @agent.roles.find_by(organisation: @organisation).destroy!
      @agent.plage_ouvertures.where(organisation: @organisation).each(&:destroy!)
      @agent.soft_delete if should_soft_delete?
    end
  end

  def no_upcoming_rdv
    if @agent.rdvs.where(organisation: @organisation).future.not_cancelled.any?
      errors.add(:base, I18n.t("admin.territories.agent_roles.destroy.cannot_delete_because_of_rdvs", agent_name: @agent.full_name, org_name: @organisation.name))
    end
  end

  def should_soft_delete?
    (@agent.organisations - [@organisation]).empty?
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
