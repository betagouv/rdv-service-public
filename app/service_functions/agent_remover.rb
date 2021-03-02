module AgentRemover

  def self.remove(agent, organisation)
    return false if upcoming_rdvs?(agent, organisation)

    Agent.transaction do
      agent.organisations.delete(organisation)
      agent.absences.where(organisation: organisation).each(&:destroy!)
      agent.plage_ouvertures.where(organisation: organisation).each(&:destroy!)
      agent.soft_delete if agent.only_in_this_organisation?(organisation)
      true
    end
  end

  def self.upcoming_rdvs?(agent, organisation)
    agent.rdvs.where(organisation: organisation).future.not_cancelled.any?
  end
end
