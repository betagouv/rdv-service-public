class AgentAgenda
  attr_reader :organisation, :agent

  def initialize(organisation: nil, agent: nil)
    @organisation = organisation
    @agent = agent
  end

  def organisation_id
    organisation.id
  end

  def agent_id
    agent.id
  end
end
