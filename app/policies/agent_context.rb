# frozen_string_literal: true

class AgentContext
  attr_reader :agent

  def initialize(agent)
    @agent = agent
  end
end
