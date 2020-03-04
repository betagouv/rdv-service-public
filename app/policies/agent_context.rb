class AgentContext
  attr_reader :agent, :organisation, :selected_agent

  def initialize(agent, selected_agent, organisation = nil)
    @agent = agent
    @selected_agent = selected_agent || agent
    @organisation = organisation
  end
end
