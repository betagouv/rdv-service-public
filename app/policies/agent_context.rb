class AgentContext
  attr_reader :agent, :organisation

  def initialize(agent, organisation = nil)
    @agent = agent
    @organisation = organisation
  end
end
