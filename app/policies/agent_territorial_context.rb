# frozen_string_literal: true

class AgentTerritorialContext
  attr_reader :agent, :territory

  def initialize(agent, territory)
    @agent = agent
    @territory = territory
  end
end
