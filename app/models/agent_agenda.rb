class AgentAgenda
  attr_reader :organisation, :agent

  def initialize(organisation: nil, agent: nil)
    @organisation = organisation
    @agent = agent
  end

  delegate :id, to: :organisation, prefix: true

  delegate :id, to: :agent, prefix: true
end
