class AgentRemoval
  def initialize(agent, organisation)
    @agent = agent
    @organisation = organisation
  end

  def remove!
    return false if upcoming_rdvs?

    Agent.transaction do
      @agent.organisations.delete(@organisation)
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
  alias will_soft_delete? should_soft_delete?
end
