class Notifiers::Agent::AddedToRdv
  def initialize(rdv:, author:, agent_ids:)
    @rdv = rdv
    @author = author
    @agent_ids = agent_ids
  end

  def notify_agents
    agents.select do |agent|
      Notifiers::AgentsConcern.should_notify_agent?(@rdv, agent, @author)
    end.each do |agent|
      Agents::RdvMailer.with(agent: agent, rdv: @rdv).rdv_created.deliver_later
    end
  end

  private

  def agents
    Agent.where(id: @agent_ids)
  end
end
