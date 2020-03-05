class AgentContext
  attr_reader :agent, :organisation, :selected_agent

  def initialize(agent, organisation = nil)
    @agent = agent
    @organisation = organisation
  end
end
